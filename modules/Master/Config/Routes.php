<?php

$routes->get('/', 'Home::index');

service('auth')->routes($routes);