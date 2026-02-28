<?php

namespace Modules\Master\Controllers;

class Home extends \App\Controllers\BaseController
{
	public function index(): string
	{
		return view('Modules\Master\Views\welcome_message');
	}
}