/// Système de traduction léger pour Fafoutt Store.
/// Couvre les écrans les plus utilisés au quotidien : POS, Stocks,
/// Paramètres, ainsi que la navigation principale.
const Map<String, Map<String, String>> kTranslations = {
  'fr': {
    // Navigation
    'nav_home': 'Accueil',
    'nav_sales': 'Vente',
    'nav_stock': 'Stocks',
    'nav_reports': 'Rapports',

    // POS
    'pos_subtitle': 'Point de Vente',
    'pos_search_hint': 'Rechercher un produit ou un code...',
    'pos_all_category': 'Tout',
    'pos_cart_title': 'Panier',
    'pos_cart_empty': 'Le panier est vide\nTouchez un produit pour l\'ajouter',
    'pos_view_cart': 'Voir le panier',
    'pos_checkout_button': 'PASSER AU PAIEMENT',
    'pos_no_product_found': 'Aucun produit trouvé',

    // Stocks
    'stock_subtitle': 'Gestion des stocks',
    'stock_search_hint': 'Rechercher un produit ou un code...',
    'stock_low_stock_filter': 'Stock bas',
    'stock_no_product': 'Aucun produit trouvé',
    'stock_in_stock': 'en stock',

    // Paramètres
    'settings_title': 'Paramètres',
    'settings_store_info': 'Informations du magasin',
    'settings_store_name': 'Nom du magasin',
    'settings_language': 'Langue',
    'settings_save': 'ENREGISTRER LES PARAMÈTRES',
    'settings_backup': 'Sauvegarde des données',
    'settings_backup_button': 'SAUVEGARDER MES DONNÉES',
    'settings_restore_button': 'RESTAURER UNE SAUVEGARDE',
  },
  'ht': {
    // Navigasyon
    'nav_home': 'Akèy',
    'nav_sales': 'Vann',
    'nav_stock': 'Estòk',
    'nav_reports': 'Rapò',

    // POS
    'pos_subtitle': 'Pwen Vant',
    'pos_search_hint': 'Chèche yon pwodwi oswa yon kòd...',
    'pos_all_category': 'Tout',
    'pos_cart_title': 'Panye',
    'pos_cart_empty': 'Panye a vid\nTouche yon pwodwi pou ajoute li',
    'pos_view_cart': 'Gade panye a',
    'pos_checkout_button': 'ALE NAN PEMAN',
    'pos_no_product_found': 'Pa gen pwodwi jwenn',

    // Estòk
    'stock_subtitle': 'Jesyon estòk',
    'stock_search_hint': 'Chèche yon pwodwi oswa yon kòd...',
    'stock_low_stock_filter': 'Estòk ba',
    'stock_no_product': 'Pa gen pwodwi jwenn',
    'stock_in_stock': 'nan estòk',

    // Paramèt
    'settings_title': 'Paramèt',
    'settings_store_info': 'Enfòmasyon magazen an',
    'settings_store_name': 'Non magazen an',
    'settings_language': 'Lang',
    'settings_save': 'ANREJISTRE PARAMÈT YO',
    'settings_backup': 'Sovgad done yo',
    'settings_backup_button': 'SOVGADE DONE MWEN YO',
    'settings_restore_button': 'REKONSTITYE YON SOVGAD',
  },
};

/// Traduit une clé selon la langue active ('fr' ou 'ht'), avec repli
/// automatique sur le français si la clé ou la langue est introuvable.
String tr(String language, String key) {
  return kTranslations[language]?[key] ?? kTranslations['fr']![key] ?? key;
}
