define([
    'vendor/base',
    'views/widget-view',
    'models/cost',
    'text!templates/total-cost.html.haml',
    'text!templates/github.html.haml',
    'text!templates/index.html.haml'
], function (BackboneSuperView, WidgetView, Cost, totalCostTemplate, githubTemplate, template) {
    return BackboneSuperView.extend({

        id: 'index-view',

        template: template,

        totalCostView: null,

        initialize: function (options) {
            this.costModel = new Cost();
            this.bindTo(this.costModel, 'change', function () {
                this.renderTotalCost();
            });
            this.costModel.fetch();
        },

        postRender: function () {
            this.totalCostView = new WidgetView({
                 heading: 'Total Cost',
                 contentId: 'total-cost-widget'
            }).render();
            this.totalCostView.append('<div id="loading-total-cost"></div>');
            this.$el.append(this.totalCostView.el);

            this.githubView = new WidgetView({
                 heading: 'Github',
                 contentId: 'github-widget'
            }).render();
            this.githubView.append("<div class='github-widget' data-repo='" + githubUser + "/" + githubProject + "'>");
            this.$el.append(this.githubView.el);
            github();
        },

        spinner: function () {
            if (this.totalCostView.$('#loading-total-cost svg').length === 0) {
                spinner('loading-total-cost', 50, 45, 15, 3, '#888');
            }
        },

        renderTotalCost: function () {
            this.totalCostView.empty();
            this.totalCostView.appendTemplate(totalCostTemplate, this.costModel);
        }
    });
});
