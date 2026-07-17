<?php helper('html'); ?>
<?= doctype() ?>
<html lang="<?= $lang ?>">
<head>

<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="view-transition" content="same-origin" />
<meta name="description" content="<?= $this->renderSection('description') ?>">

<title><?= $this->renderSection('title') ?></title>

<base href="<?= site_url() ?>">

<?= link_tag('/favicon.svg', 'icon', 'image/svg+xml') ?>
<?= link_tag('css/main.css') ?>

<?= $this->renderSection('prepend') ?>
</head>
<body>
<?= $this->renderSection('main') ?>
<?= $this->renderSection('append') ?>
</body>
</html>