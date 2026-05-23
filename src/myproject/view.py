
from django.shortcuts import render
from visit.models import PageVisits

def homePage(request):
    queryset=PageVisits.objects.all()
    context={"queryset":queryset}

    return render(request, 'home.html',context)    
def aboutPage(request):
    return render(request,'about.html')

