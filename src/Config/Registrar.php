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

	public static function Filters(): array
	{
		return [
			// Disables CodeIgniter4 toolbar
			'required' => [
				'after' => [
					//'pagecache',	// Web Page Caching
					//'performance',	// Performance Metrics
					//'toolbar',		// Debug Toolbar
				],
			],
			// Protects all site pages with Shield
			'globals' => [
				'before' => [
					'csrf',
					'session' => [
						'except' => [
							'login*',
							'register',
							'auth/a/*',
						],
					],
				],
				'after' => [
					'secureheaders',
				],
			],
		];
	}

	public static function Security(): array
	{
		// Shield modifies app/Config/Security.php but should be something configurable in Registrar to maintain install parity
		return [
			'csrfProtection' => 'session',
			'tokenRandomize' => true,
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
			'negotiateLocale' => true,
			'CSPEnabled' => true,
			'forceGlobalSecureRequests' => ENVIRONMENT === 'production',
		];
	}

	public static function ContentSecurityPolicy(): array
	{
		return [
			'reportOnly' => false,
			'reportURI' => null,
			'reportTo' => null,
			'upgradeInsecureRequests' => true,
			'defaultSrc' => 'none',
			'scriptSrc' => 'strict-dynamic',
			'scriptSrcElem' => 'strict-dynamic',
			'scriptSrcAttr' => 'none',
			'styleSrc' => 'self',
			'styleSrcElem' => 'self',
			'styleSrcAttr' => 'self',
			'imageSrc' => 'self',
			'baseURI' => 'none',
			'childSrc' => 'none',
			'connectSrc' => 'self',
			'fontSrc' => 'none',
			'formAction' => 'self',
			'frameAncestors' => 'none',
			'mediaSrc' => 'none',
			'objectSrc' => 'none',
			'manifestSrc' => 'none',
			'workerSrc' => [],
			'pluginTypes' => null,
			'sandbox' => null,
			'styleNonceTag' => '{csp-style-nonce}',
			'scriptNonceTag' => '{csp-script-nonce}',
			'autoNonce' => true,	// Set this way for generic install to permit generic home page view, should be switched to false and use csp_script_nonce() or csp_style_nonce() functions, respectively
		];
	}

	public static function Exceptions(): array
	{
		return [
			'errorViewPath' => ROOTPATH . 'modules/master/src/Views/errors',
		];
	}

	public static function Routing(): array
	{
		return [
			'defaultNamespace' => 'Modules\Master\Controllers',
		];
	}
}
