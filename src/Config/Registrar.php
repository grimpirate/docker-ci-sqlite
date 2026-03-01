<?php

namespace Modules\Master\Config;

class Registrar
{
	public static function Email(): array
	{
		// Required for shield:setup migrations to proceed successfully
		return [
			'fromEmail' => 'anonym@us.com',
			'fromName' => 'anonym@us',
		];
	}

	public static function Auth(): array
	{
		return [
			'allowRegistration' => true,
		];
	}

	public static function Filters(): array
	{
		return [
			// Disables CodeIgniter4 toolbar
			'required' => [
				'after' => [
					'pagecache',	// Web Page Caching
					'performance',	// Performance Metrics
					//'toolbar',		// Debug Toolbar
				],
			],
			// Protects all site pages with Shield
			'globals' => [
				'before' => [
					'session' => [
						'except' => [
							'login*',
							'register',
							'auth/a/*',
						],
					],
				],
			],
		];
	}

	public static function Security(): array
	{
		// Shield modifies app/Config/Security.php but should be something configurable in Registrar to maintain install parity
		return [
			'csrfProtection' => 'session',
		];
	}

	public static function Database(): array
	{
		// SQLite .db file located in writable/ directory
		return [
			'default' => [
				'database' => $_ENV['docker.db_name'],
				'DBDriver' => 'SQLite3',
			],
		];
	}

	public static function App(): array
	{
		return [
			'indexPage' => '',
			'appTimezone' => $_ENV['docker.tz_country'] . '/' . $_ENV['docker.tz_city'],
			'baseURL' => $_ENV['docker.ci_baseurl'],
			'defaultLocale' => 'en',
			'negotiateLocale' => true,
			//'supportedLocales' => ['en'],	// English locale supported by default
		];
	}

	public static function Exceptions(): array
	{
		return [
			'errorViewPath' => ROOTPATH . 'modules/Master/Views/errors',
		];
	}

	public static function Routing(): array
	{
		return [
			'defaultNamespace' => 'Modules\Master\Controllers',
		];
	}
}
