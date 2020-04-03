from django import forms

class VoteForm(forms.Form):
  vote = forms.CharField()
