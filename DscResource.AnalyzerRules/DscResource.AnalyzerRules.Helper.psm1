<#
    .SYNOPSIS
        Helper function to check if an Ast is part of a class.
        Returns true or false
    .EXAMPLE
        IsInClass -Ast $ParameterBlockAst

    .INPUTS
        [System.]

    .OUTPUTS
        [System.String[]]

   .NOTES
        None
#>
function Test-IsInClass
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Ast]
        $Ast
    )

    <# 
        Check if Parameter is in a method call for a Class
        or if a Named Attribute is part of a Class Property

        I initially just walked up the AST tree till I hit
        a TypeDefinitionAst that was a class

        But...

        That means it would throw false positives for things like

        class HasAFunctionInIt
        {
            [Func[int,int]] $MyFunc = {
                param
                (
                    [Parameter(Mandatory=$true)]
                    [int]
                    $Input
                )

                $Input
            }
        }

        Where the param block and all its respective items ARE
        valid being in their own anonymous function definition
        that just happens to be inside a class property's
        assignment value

        So This check has to be a DELIBERATE step by step up the
        AST Tree ONLY far enough to validate if it is directly
        part of a class or not
    #>
    [bool] $InAClass = $false
    <#  
        As far as I know the only place you can have nammed
        Attribute Arguments in Classes is on Properties.
        Arguments in Methods of classes only support Types
        
        This makes it easy to say If its part of an Attribute
        That is part of a PropertyMember
        That is part of a TypeDefinition
        This Is a class

        That our Named Attribute Argument is part of a class
    #>
    if ($Ast -is [System.Management.Automation.Language.NamedAttributeArgumentAst])
    {
        $InAClass = $Ast.Parent -is [System.Management.Automation.Language.AttributeAst] -and 
            $Ast.Parent.Parent -is [System.Management.Automation.Language.PropertyMemberAst] -and
            $Ast.Parent.Parent.Parent -is [System.Management.Automation.Language.TypeDefinitionAst] -and
            $ast.Parent.Parent.Parent.IsClass
    }
    <#
        Since classes do not support param blocks inside
        Their method bodies, we only have to check if it is 
        part of a FunctionDefintion
        That is part of a FunctionMember (Class Method)
        That is part of a TypeDefinition
        That is a class

        then our Parameter is part of a class
    #>
    elseif ($Ast -is [System.Management.Automation.Language.ParameterAst])
    {
        $InAClass = $Ast.Parent -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $Ast.Parent.Parent -is [System.Management.Automation.Language.FunctionMemberAst] -and
            $Ast.Parent.Parent.Parent -is [System.Management.Automation.Language.TypeDefinitionAst] -and
            $Ast.Parent.Parent.Parent.IsClass
    }
    $InAClass
}

<#
    .SYNOPSIS
        Helper function for the Test-Statement* helper functions.
        Returns the extent text as an array of strings.

    .EXAMPLE
        Get-StatementBlockAsRows -StatementBlock $ScriptBlockAst.Extent

    .INPUTS
        [System.String]

    .OUTPUTS
        [System.String[]]

   .NOTES
        None
#>
function Get-StatementBlockAsRows
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $StatementBlock
    )

    <#
        Remove carriage return since the file is different depending if it's run in
        AppVeyor or locally. Locally it contains both '\r\n', but when cloned in
        AppVeyor it only contains '\n'.
    #>
    $statementBlockWithNewLine = $StatementBlock -replace '\r', ''
    return $statementBlockWithNewLine -split '\n'
}

<#
    .SYNOPSIS
        Helper function for the Measure-*Statement PSScriptAnalyzer rules.
        Test a single statement block for opening brace on the same line.

    .EXAMPLE
        Test-StatementOpeningBraceOnSameLine -StatementBlock $ScriptBlockAst.Extent

    .INPUTS
        [System.String]

    .OUTPUTS
        [System.Boolean]

   .NOTES
        None
#>
function Test-StatementOpeningBraceOnSameLine
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $StatementBlock
    )

    $statementBlockRows = Get-StatementBlockAsRows -StatementBlock $StatementBlock
    if ($statementBlockRows.Count)
    {
        # Check so that an opening brace does not exist on the same line as the statement.
        if ($statementBlockRows[0] -match '{[\s]*$')
        {
            return $true
        } # if
    } # if

    return $false
}

<#
    .SYNOPSIS
        Helper function for the Measure-*Statement PSScriptAnalyzer rules.
        Test a single statement block for new line after opening brace.

    .EXAMPLE
        Test-StatementOpeningBraceIsNotFollowedByNewLine -StatementBlock $ScriptBlockAst.Extent

    .INPUTS
        [System.String]

    .OUTPUTS
        [System.Boolean]

   .NOTES
        None
#>
function Test-StatementOpeningBraceIsNotFollowedByNewLine
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $StatementBlock
    )

    $statementBlockRows = Get-StatementBlockAsRows -StatementBlock $StatementBlock
    if ($statementBlockRows.Count -ge 2)
    {
        # Check so that an opening brace is followed by a new line.
        if ($statementBlockRows[1] -match '\{.+')
        {
            return $true
        } # if
    } # if

    return $false
}

<#
    .SYNOPSIS
        Helper function for the Measure-*Statement PSScriptAnalyzer rules.
        Test a single statement block for only one new line after opening brace.

    .EXAMPLE
        Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine -StatementBlock $ScriptBlockAst.Extent

    .INPUTS
        [System.String]

    .OUTPUTS
        [System.Boolean]

   .NOTES
        None
#>
function Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $StatementBlock
    )

    $statementBlockRows = Get-StatementBlockAsRows -StatementBlock $StatementBlock
    if ($statementBlockRows.Count -ge 3)
    {
        # Check so that an opening brace is followed by only one new line.
        if (-not $statementBlockRows[2].Trim())
        {
            return $true
        } # if
    } # if

    return $false
}

