local uuid = require 'uuid'
local json = require 'cjson'
local tablex = require 'pl.tablex'
require 'pl.text'.format_operator()
require 'image'
local itorch = require 'itorch._env'
local util = require 'itorch.util'

local bokeh_template = 
[[
<script type="text/javascript">
  $(function() {
    var modelid = "${model_id}";
    var modeltype = "PlotContext";
    var all_models = {${all_models}};
    Bokeh.load_models(all_models);
    var model = Bokeh.Collections(modeltype).get(modelid);
    $("#${window_id}").html(''); // clear any previous plot in window_id
    var view = new model.default_view({model: model, el: "#${window_id}"});
  });
</script>
<div class="plotdiv" id="${div_id}"></div>
]]

-- model_id, all_models, window_id, div_id
-- doc: https://github.com/bokeh/Bokeh.jl/blob/master/doc/other/bokeh_bindings.md
function itorch.draw(allmodels, window_id)
   assert(type(allmodels) == 'table'
             and allmodels[1] and allmodels[1].id,
          "argument 1 is not a plot object")
   assert(itorch._iopub,'itorch._iopub socket not set')
   assert(itorch._msg,'itorch._msg not set')

   -- find model_id
   local model_id
   for k,v in ipairs(allmodels) do
      if v.type == 'PlotContext' then
         model_id = v.id
      end
   end
   assert(model_id, "Could not find PlotContext element in input Plot");

   local div_id = uuid.new()
   window_id = window_id or div_id
   local content = {}
   content.source = 'itorch'
   content.data = {}
   content.data['text/html'] =
      bokeh_template % {
         window_id = window_id,
         div_id = div_id,
         all_models = json.encode(allmodels),
         model_id = model_id
                       };
   content.metadata = {}
   local header = tablex.deepcopy(itorch._msg.header)
   header.msg_id = uuid.new()
   header.msg_type = 'display_data'

   -- send displayData
   local m = {
      uuid = itorch._msg.uuid,
      content = content,
      parent_header = itorch._msg.header,
      header = header
   }
   util.ipyEncodeAndSend(itorch._iopub, m)
   return window_id
end

-- 2D charts
-- scatter
-- bar (grouped and stacked)
-- pie
-- histogram
-- area-chart (http://bokeh.pydata.org/docs/gallery/brewer.html)
-- categorical heatmap
-- timeseries
-- confusion matrix
-- image_rgba
-- candlestick
-- vectors
------------------
-- 2D plots
-- line plot
-- log-scale plots
-- semilog-scale plots
-- error-bar / candle-stick plot
-- contour plots
-- polar plots / angle-histogram plot / compass plot (arrowed histogram)
-- vector fields (feather plot, quiver plot, compass plot, 3D quiver plot)
-------------------------
-- 3D plots
-- line plot
-- scatter-3D ************** (important)
-- contour-3D
-- 3D shaded surface plot (surf/surfc)
-- surface normals
-- mesh plot
-- ribbon plot (for fun)

-- create a torch.peaks (useful)
--------------------------------------------------------------------
-- view videos
--

-- grid plots http://nbviewer.ipython.org/github/ContinuumIO/bokeh-notebooks/blob/master/quickstart/quickstart.ipynb

function itorch.demo(window_id)
   require 'itorch.test'
end

return itorch;
