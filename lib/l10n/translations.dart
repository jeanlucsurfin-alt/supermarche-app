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

    // Rapports
    'reports_subtitle': 'Rapports de ventes',
    'reports_filter_today': 'Aujourd\'hui',
    'reports_filter_week': '7 derniers jours',
    'reports_filter_month': 'Ce mois',
    'reports_filter_custom': 'Personnalisé',
    'reports_total_outstanding_credit': 'Total des créances en cours',
    'reports_revenue': 'Chiffre d\'affaires',
    'reports_transaction_count': 'Nombre de ventes',
    'reports_realized_profit': 'Bénéfice réalisé',
    'reports_pending_profit': 'Bénéfice en attente (crédit)',
    'reports_average_basket': 'Panier moyen',
    'reports_credit_granted': 'Crédit accordé (période)',
    'reports_returns_period': 'Retours (période)',
    'reports_expenses_period': 'Dépenses (période)',
    'reports_net_profit': 'Bénéfice net',
    'reports_top_products': 'Produits les plus vendus',
    'reports_no_sales_period': 'Aucune vente sur cette période',
    'reports_payment_methods': 'Ventes par mode de paiement',
    'reports_no_data': 'Aucune donnée',
    'reports_export_pdf': 'Exporter en PDF',
    'reports_export_csv': 'Exporter en Excel (CSV)',
    'reports_sales_suffix': 'vente(s)',
    'payment_cash': 'Cash',
    'payment_card': 'Carte',
    'payment_mobile_money': 'Mobile Money',
    'payment_credit': 'Crédit',
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

    // Rapò
    'reports_subtitle': 'Rapò vant yo',
    'reports_filter_today': 'Jodi a',
    'reports_filter_week': '7 dènye jou yo',
    'reports_filter_month': 'Mwa sa a',
    'reports_filter_custom': 'Pèsonalize',
    'reports_total_outstanding_credit': 'Total kredi ki poko peye',
    'reports_revenue': 'Chif dafè',
    'reports_transaction_count': 'Kantite vant',
    'reports_realized_profit': 'Benefis reyalize',
    'reports_pending_profit': 'Benefis ki poko rive (kredi)',
    'reports_average_basket': 'Panye mwayèn',
    'reports_credit_granted': 'Kredi bay (peryòd)',
    'reports_returns_period': 'Retou (peryòd)',
    'reports_expenses_period': 'Depans (peryòd)',
    'reports_net_profit': 'Benefis nèt',
    'reports_top_products': 'Pwodwi ki pi vann yo',
    'reports_no_sales_period': 'Pa gen vant nan peryòd sa a',
    'reports_payment_methods': 'Vant selon mòd peman',
    'reports_no_data': 'Pa gen done',
    'reports_export_pdf': 'Ekspòte an PDF',
    'reports_export_csv': 'Ekspòte an Excel (CSV)',
    'reports_sales_suffix': 'vant',
    'payment_cash': 'Kach',
    'payment_card': 'Kat',
    'payment_mobile_money': 'Mobile Money',
    'payment_credit': 'Kredi',
  },
};

/// Traduit une clé selon la langue active ('fr' ou 'ht'), avec repli
/// automatique sur le français si la clé ou la langue est introuvable.
String tr(String language, String key) {
  return kTranslations[language]?[key] ?? kTranslations['fr']![key] ?? key;
}
