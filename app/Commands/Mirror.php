<?php

namespace App\Commands;

use CodeIgniter\CLI\BaseCommand;
use CodeIgniter\CLI\CLI;

class Mirror extends BaseCommand
{
	protected $group       = 'Mirror';
	protected $name        = 'make:mirror';

	public function run(array $params)
	{
		$root = self::listAllFiles(ROOTPATH);

		mkdir(ROOTPATH . '../mirror');
		mkdir(ROOTPATH . '../mirror/app');
		mkdir(ROOTPATH . '../mirror/app/Config');
		mkdir(ROOTPATH . '../mirror/public');

		foreach(array_filter($root, function($path) {
			if(1 === preg_match('/^.*\/app\/Config$/', $path)) return false;
			if(1 === preg_match('/^.*\/app\/[^\/]+$/', $path)) return true;
			return false;
		}) as $path)
			symlink($path, preg_replace('/^(.*\/)([^\/]+)(\/app\/.*)$/', '$1mirror$3', $path));

		foreach(array_filter($root, function($path) {
			if(1 === preg_match('/^.*\/app\/Config\/(?:Constants|Paths|Registrar)\.php$/', $path)) return false;
			if(1 === preg_match('/^.*\/app\/Config\/[^\/]+$/', $path)) return true;
			return false;
		}) as $path)
			symlink($path, preg_replace('/^(.*\/)([^\/]+)(\/app\/.*)$/', '$1mirror$3', $path));

		foreach(array_filter($root, function($path) {
			if(1 === preg_match('/^.*\/public\/index\.php$/', $path)) return false;
			if(1 === preg_match('/^.*\/public\/[^\/]+$/', $path)) return true;
			return false;
		}) as $path)
			symlink($path, preg_replace('/^(.*\/)([^\/]+)(\/public\/.*)$/', '$1mirror$3', $path));

		foreach(array_filter($root, function($path) {
			if(1 === preg_match('/^.*\/app\/Config\/(?:Constants|Paths|Registrar)\.php$/', $path)) return true;
			return false;
		}) as $path)
			copy($path, preg_replace('/^(.*\/)([^\/]+)(\/app\/.*)$/', '$1mirror$3', $path));

		foreach(array_filter($root, function($path) {
			if(1 === preg_match('/^.*\/public\/index\.php$/', $path)) return true;
			return false;
		}) as $path)
			copy($path, preg_replace('/^(.*\/)([^\/]+)(\/public\/.*)$/', '$1mirror$3', $path));

		foreach(array_filter($root, function($path) {
			if(1 === preg_match('/^.*\/(?:\.env|spark)$/', $path)) return true;
			return false;
		}) as $path)
			copy($path, preg_replace('/^(.*\/)([^\/]+)(\/(?:\.env|spark))$/', '$1mirror$3', $path));
	}

	public static function listAllFiles($dir)
	{
		$array = array_diff(scandir($dir), array('.', '..'));

		foreach($array as &$item)
			$item = $dir . $item;

		unset($item);

		foreach($array as $item)
			if(is_dir($item))
				$array = array_merge($array, self::listAllFiles($item . DIRECTORY_SEPARATOR));

		return $array;
	}
}