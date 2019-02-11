git add --all
git commit -m "Updates"
git push origin speedup
ssh tt15951@bluecrystalp3.acrc.bris.ac.uk
cd year-4-computing
git fetch origin speedup
git reset --hard origin/speedup
python setup.py build_ext -fi
# qsub -q teaching ./bc.sh
