import apolloProvider from "@/vue-apollo";
import { NormalizedCacheObject } from "@apollo/client/cache/inmemory/types";
import { ApolloClient } from "@apollo/client/core/ApolloClient";
import { WEB_PUSH } from "../graphql/config";
import { IConfig } from "../types/config.model";

function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

export async function subscribeUserToPush(): Promise<PushSubscription | null> {
  const client =
    apolloProvider.defaultClient as ApolloClient<NormalizedCacheObject>;

  const registration = await navigator.serviceWorker.ready;
  const { data } = await client.query<{ config: IConfig }>({
    query: WEB_PUSH,
  });

  if (data?.config?.webPush?.enabled && data?.config?.webPush?.publicKey) {
    const subscribeOptions = {
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(
        data?.config?.webPush?.publicKey
      ),
    };
    try {
      const pushSubscription = await registration.pushManager.subscribe(
        subscribeOptions
      );
      console.debug("Received PushSubscription: ", pushSubscription);
      return pushSubscription;
    } catch (e) {
      console.error("Error while subscribing to push notifications", e);
    }
  }
  return null;
}

export async function unsubscribeUserToPush(): Promise<string | undefined> {
  console.log("performing unsubscribeUserToPush");
  const registration = await navigator.serviceWorker.ready;
  console.log("found registration", registration);
  const subscription = await registration.pushManager?.getSubscription();
  console.log("found subscription", subscription);
  if (subscription && (await subscription?.unsubscribe()) === true) {
    console.log("done unsubscription");
    return subscription?.endpoint;
  }
  console.log("went wrong");
  return undefined;
}
