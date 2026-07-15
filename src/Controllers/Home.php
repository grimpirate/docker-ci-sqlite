<?php
declare(strict_types=1);

namespace Modules\Master\Controllers;

use CodeIgniter\Security\CheckPhpIni;

class Home extends \App\Controllers\BaseController
{
	public function index(): string
	{
		return CheckPhpIni::run(false);
		//return view('Modules\Master\Views\welcome_message');
	}
}
