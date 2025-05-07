git config --global user.email "devops@example.com"
git config --global user.name "DevOps Bot"
git clone https://$(GITHUB_TOKEN)@github.com/ukez15/aks-store-devops-assessment.git
cd aks-store-demo/store-app
sed -i "s/tag: .*/tag: $(IMAGE_TAG)/" values.yaml
git add values.yaml
git commit -m "Update image tag to $(IMAGE_TAG)"
git push origin main