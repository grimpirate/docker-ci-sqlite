<?php

namespace Modules\Master\Views\Decorators;

use CodeIgniter\View\ViewDecoratorInterface;
use voku\helper\HtmlMin;

class MinifyDecorator implements ViewDecoratorInterface
{
    public static function decorate(string $html): string
    {
        $minifier = new HtmlMin();
        $minifier->doMinifyJavaScript();
        $minifier->doRemoveWhitespaceAroundTags();
        $minifier->doOptimizeAttributes();
        $minifier->doRemoveHttpPrefixFromAttributes();
        $minifier->doRemoveHttpsPrefixFromAttributes();
        $minifier->setLocalDomains([str_replace('/', '', base_url('', ''))])->doMakeSameDomainsLinksRelative();
        $minifier->doSortCssClassNames();
        $minifier->doSortHtmlAttributes();
        $minifier->doRemoveSpacesBetweenTags();
        return $minifier->minify($html);
    }
}