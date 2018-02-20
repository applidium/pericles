let resourcesFromCache = JSON.parse(localStorage.getItem('resources') || '[]');

export default {
  state: {
    displayedResources: resourcesFromCache,
    resources: resourcesFromCache,
    projectId: document.location.pathname.split('/')[2],
    treeMode: localStorage.getItem('treeMode') == 'tree',
    query: ''
  },
  fetchResources: function() {
    return $.ajax({
      type: "GET",
      url: '/projects/' + this.state.projectId + '/resources.json',
      contentType: "application/json",
    }).then((data) => {
      this.state.resources = this.mapDataToViewModel(data);
      localStorage.setItem('resources', JSON.stringify(this.state.resources));
    });
  },
  mapDataToViewModel: function(data) {
    return data['resources'].map((r) => {
      return {
        id: r.id,
        name: r.name,
        usedResources: r.used_resources,
        hasInvalidMocks: r['has_invalid_mocks?']
      }
    }).sort(
      (a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase())
    );
  },
  toggleTreeMode: function() {
    if (this.state.treeMode) {
      this.deactiveTreeMode();
    } else {
      this.activeTreeMode();
    }
  },
  activeTreeMode: function () {
    this.state.treeMode = true;
    localStorage.setItem('treeMode', 'tree');
  },
  deactiveTreeMode: function () {
    this.state.treeMode = false;
    localStorage.setItem('treeMode', '');
  },
  findResourcesByIds: function(ids) {
    return this.state.resources.filter((r) => ids.indexOf(r.id) !== -1)
  },
  flatChildren: function(resource) {
    let visited = new Set();
    let queue = resource.usedResources.map((r) => r.id);

    while (queue.length > 0) {
      let resourceId = queue.pop();

      if(!visited.has(resourceId)) {
        visited.add(resourceId);
        let resource = this.state.resources.find((r) => r.id === resourceId);
        queue = queue.concat(resource.usedResources.map((r) => r.id));
      }
    }

    return this.state.resources.filter((r) => visited.has(r.id));
  },
  setQuery: function(value) {
    this.state.query = value;
    this.onQueryChange();
  },
  onQueryChange: function() {
    this.applyFilter();
  },
  applyFilter: function() {
    let q = this.state.query.toLowerCase();
    if (q.length === 0) {
      this.state.displayedResources = this.state.resources;
    } else {
      this.state.displayedResources = this.state.resources.filter(
        (r) => {
          let resourceFound = r.name.toLowerCase().indexOf(q) !== -1
          let someChildrenFound = this.flatChildren(r).some(
            (child) => child.name.toLowerCase().indexOf(q) !== -1
          )
          return resourceFound || (this.state.treeMode && someChildrenFound);
        }
      );
    }
  }
}