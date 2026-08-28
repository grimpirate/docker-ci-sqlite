<?php

namespace Modules\Master\Views\Decorators;

use CodeIgniter\View\ViewDecoratorInterface;

use Akankov\HtmlMin\Config\MinifierOptions;
use Akankov\HtmlMin\HtmlMin;

use MatthiasMullie\Minify;

class MinifyDecorator implements ViewDecoratorInterface
{
    public static function decorate(string $html): string
    {
        return (new HtmlMin(MinifierOptions::aggressive()))
            ->doMakeSameDomainsLinksRelative([str_replace('/', '', base_url('',''))])
            ->setInlineCssMinifier(static fn (string $css): string => (new Minify\CSS($css))->minify())
            ->setInlineJsMinifier(static fn (string $js): string => (new Minify\JS($js))->minify())
            ->minify($html);
    }
}