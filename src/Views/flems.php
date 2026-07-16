<?= $this->extend('Modules\Master\Views\extensible\default') ?>
<?= $this->section('title') ?><?= $title ?><?= $this->endSection() ?>
<?= $this->section('description') ?><?= $description ?><?= $this->endSection() ?>
<?= $this->section('prepend') ?>
<style>
/* https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API */
@view-transition {
	navigation: auto;
}
html
{
	box-sizing: border-box;
}
*,
*:before,
*:after
{
	box-sizing: inherit;
}
*:not(dialog)
{
	margin: 0;
}
html,
body
{
	width: 100%;
	height: 100%;
}
</style>
<script src="https://unpkg.com/mithril"></script>
<?= $this->endSection() ?>
<?= $this->section('main') ?>
<?= $this->endSection() ?>
<?= $this->section('append') ?>
<script src="https://flems.io/flems.html" type="text/javascript" charset="utf-8"></script>
<script>
(() => {
	Flems(document.body, {
		files: [
			{ name: '.html', content:
`<!DOCTYPE html>
<html lang="<?= $lang ?>">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="view-transition" content="same-origin" />

<title></title>

<base href="<?= site_url() ?>">

<script src="https://unpkg.com/mithril">\</script\>
</head>
<body>
</body>
</html>`
			},
			{ name: '.js', content:
`m.render(document.body, m('h1', 'Hello world'))`
			},
			{ name: '.css', content:
`/* https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API */
@view-transition {
	navigation: auto;
}
html
{
	box-sizing: border-box;
}
*,
*:before,
*:after
{
	box-sizing: inherit;
}
*:not(dialog)
{
	margin: 0;
}`				
			},
		],
/*
		links: [
			{
				name: 'mithril',
				type: 'script',
				url: 'https://unpkg.com/mithril',
			},
		],
*/
	});
})();
</script>
<?= $this->endSection() ?>