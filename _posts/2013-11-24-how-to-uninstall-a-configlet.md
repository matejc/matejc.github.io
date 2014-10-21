---
layout: post
title: How to uninstall a configlet?
tags:
- plone
comments: true
---

How to uninstall a configlet in my add-on (, that was installed by my add-on)?


- with genericsetup (only xml)
    - knowing that documentation said that configlet can not be removed that way but documentation is over 1200 days old, talking about: [uninstall profile](http://plone.org/documentation/kb/genericsetup/creating-an-uninstall-profile)
    - I registered an uninstall profile in configure.zcml
    - copied over profiles/default to profiles/uninstall
    - add remove="True" to configlet
    - ran plone instance and activated then deactivated my add-on
    - It is still in control panel

- without genericsetup (only python)
    - create `Extensions` folder in root of your add-on
    - in that folder create `Install.py`
    - create function named `uninstall` with first argument `portal`
    - and in it write code that calls unregisterConfiglet but this option is deprecated, if it is... there must be another way?

- with genericsetup (xml+python)
    - in Extensions/Install.py

{% highlight python %}
def uninstall(portal, reinstall=False):
    out = StringIO()
    if not reinstall:
        setup_tool = api.portal.get_tool(name='portal_setup')
        setup_tool.runAllImportStepsFromProfile('profile-plone.hud:uninstall')
        print >> out, "Ran plone.hud uninstall steps."
    return out.getvalue()
{% endhighlight %}

- in configure.zcml

{% highlight xml %}
<!-- Register the installation GenericSetup extension profile -->
<genericsetup:registerProfile
    name="default"
    title="plone.hud"
    directory="profiles/default"
    description="Plone HUD framework add-on."
    provides="Products.GenericSetup.interfaces.EXTENSION"
    />
{% endhighlight %}

{% highlight xml %}
<genericsetup:importStep
    name="plone.hud-various"
    title="Plone HUD framework Import Step"
    description="Import steps for plone.hud"
    handler="plone.hud.setuphandlers.importVarious">
</genericsetup:importStep>
{% endhighlight %}

{% highlight xml %}
<!-- Register the uninstallation GenericSetup extension profile -->
<genericsetup:registerProfile
    name="uninstall"
    title="Uninstall Plone HUD"
    directory="profiles/uninstall"
    description="Uninstall Plone HUD framework."
    provides="Products.GenericSetup.interfaces.EXTENSION"
 />
{% endhighlight %}

- in setuphandlers.py

{% highlight python %}
def importVarious(context):
    """Miscellanous steps import handle."""
    # Ordinarily, GenericSetup handlers check for the existence of XML files.
    # Here, we are not parsing an XML file, but we use this text file as a
    # flag to check that we actually meant for this import step to be run.
    # The file is found in profiles/default.
    if context.readDataFile('hud_default_various.txt'): # install
        pass # install is done by GS's XML files in profile/default
    elif context.readDataFile('hud_uninstall_various.txt'): # uninstall
        # uninstall of configlet is not supported through GS XML (yet)
        config_tool = api.portal.get_tool(name='portal_controlpanel')
        config_tool.unregisterConfiglet("hud.settings")
{% endhighlight %}

- create profiles/default/hud_default_various.txt with some random string inside

- create profiles/uninstall/hud_uninstall_various.txt with some random string inside

Generic Setup is the way to go,
it is just a small thing of using Extensions/Install.py to call uninstall profile,
there is probably a good reason why uninstall profile is not called on deactivation of add-on,
I would like to know what is up with that someday...
