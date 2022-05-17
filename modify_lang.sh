files=($(ls /home/tommy/code/mobilizon/js/src/i18n/*.json))

key="Reach your audience, create a group! Users from mobilize.berlin and other fediverse platforms can follow your group. Your event will appear in their timelines, too."

declare -A langs
langs[de]="Erreiche dein Publikum, erstelle eine Gruppe! Nutzer*innen von mobilize.berlin und anderen fediverse Plattformen können deiner Gruppe folgen. Deine Veranstaltung wird auch in deren Timelines erscheinen."
langs[fr]="Atteignez ton public, créez un groupe ! Les utilisateurs de mobilize.berlin et d'autres plateformes fediverse peuvent suivre ton groupe. Ton événement apparaîtra également dans leur timeline."
langs[es]="Llega a tu público, ¡crea un grupo! Los usuarios de mobilize.berlin y otras plataformas de fediverse pueden seguir a tu grupo. Tu evento también aparecerá en sus líneas de tiempo."
langs[it]="Raggiungi il tuo pubblico, crea un gruppo! Gli utenti di mobilize.berlin e di altre piattaforme fediverse possono seguire il vostro gruppo. Il vostro evento apparirà anche nelle loro timeline."
langs[pt_BR]="Atinja seu público, crie um grupo! Os usuários da plataforma mobilize.berlin e outras plataformas fediverse podem seguir seu grupo. Seu evento também aparecerá em suas linhas de tempo."
for lang in "${files[@]}"
do
#while read line 
    l=$(echo $lang | sed -E 's/(.*)\/(.*)\.json/\2/')
    if [ "$l" == "langs" ]; then
        break;
    fi
        jq --arg key "$key" --arg lang "${langs[$l]}" '.[$key]=$lang' $lang > "${lang}_tmp"
        mv "${lang}_tmp" $lang
done