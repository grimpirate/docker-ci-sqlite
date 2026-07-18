<?php

$routes->group('', ['namespace' => 'Modules\Master\Controllers'], static function ($routes) {
	$routes->get('/', 'Home::index');
});

service('auth')->routes($routes);