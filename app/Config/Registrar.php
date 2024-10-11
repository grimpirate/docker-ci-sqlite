<?php

namespace Config;

class Registrar
{
	public static function Email(): array
	{
		// Required for spark migration to proceed successfully
		return [
			'fromEmail' => 'anonym@us.com',
			'fromName' => 'anonym@us',
		];
	}

	public static function Auth(): array
	{
		return ['allowRegistration' => true];
	}

	public static function Filters(): array
	{
		// Protects all site pages
		// Disables CodeIgniter4 toolbar in development mode
		return [
			'required' => [
				'after' => [
					'pagecache',	// Web Page Caching
					'performance',	// Performance Metrics
					//'toolbar',		// Debug Toolbar
				],
			],
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

	public static function Database(): array
	{
		return [
			'default' => [
				'database' => $_ENV['docker.db_name'],
				'DBDriver' => 'SQLite3',
			],
			'app' => [
				'database' => 'app.db',
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
			'supportedLocales' => ['en'],
		];
	}
}
