GRAPHHOPPER_DIR=./graphhopper

.PHONY: clean clean-map

$(GRAPHHOPPER_DIR)/europe_france_rhone-alpes.pbf:
	@echo "Downloading map of Rhône-Alpes (~275MB)..."
	@curl http://download.geofabrik.de/europe/france/rhone-alpes-latest.osm.pbf -o $(GRAPHHOPPER_DIR)/europe_france_rhone-alpes.pbf

# top-left: 45.8149222464981,4.739570617675781
# top-right: 45.8149222464981,4.954833984374999
# bottom-right: 45.69538925306953,4.954833984374999
# bottom-left: 45.69538925306953,4.739570617675781
$(GRAPHHOPPER_DIR)/europe_france_rhone-alpes_lyon_velov.pbf: $(GRAPHHOPPER_DIR)/europe_france_rhone-alpes.pbf
	@echo "Extracting map of Lyon..."
	@osmosis  --read-pbf file=$(GRAPHHOPPER_DIR)/europe_france_rhone-alpes.pbf --bounding-box top=45.8149222464981 left=4.739570617675781 bottom=45.69538925306953 right=4.954833984374999 --write-pbf file=$(GRAPHHOPPER_DIR)/europe_france_rhone-alpes_lyon_velov.pbf

map: $(GRAPHHOPPER_DIR)/europe_france_rhone-alpes_lyon_velov.pbf

clean:
	@echo "Cleaning GraphHopper graph..."
	@rm -rf $(GRAPHHOPPER_DIR)/*-gh/
	@rm -rf $(GRAPHHOPPER_DIR)/srtmprovider/

clean-map: clean
	@echo "Cleaning GraphHopper maps..."
	@rm -f $(GRAPHHOPPER_DIR)/europe_france_rhone-alpes_lyon_velov.pbf
	@rm -f $(GRAPHHOPPER_DIR)/europe_france_rhone-alpes.pbf
