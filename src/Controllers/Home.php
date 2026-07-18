<?php
declare(strict_types=1);

namespace Modules\Master\Controllers;

use CodeIgniter\Security\CheckPhpIni;

class Home extends \App\Controllers\BaseController
{
	public function index(): string
	{
		return CheckPhpIni::run(false);
		
		//return view('welcome_message');

		// Requires CPSEnabled => false in Config/Registrar.php
		return view('Modules\Master\Views\flems', [
			'lang' => $this->request->getLocale(),
			'title' => 'Sandbox',
			'description' => 'Sandbox powered by Flems.io'
		]);
	}
}
