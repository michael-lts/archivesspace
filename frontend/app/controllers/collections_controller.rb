class CollectionsController < ApplicationController

   def index
      @collections = JSONModel(:collection).all
   end

   def show
     @collection = JSONModel(:collection).find(params[:id], "resolve[]" => "subjects")
  
      if params[:inline]
         return render :partial=>"collections/show_inline"
      end

     fetch_collection_tree(@collection)
   end

   def new
      @collection = JSONModel(:collection).new({:title=>"New Collection"})._always_valid!
   end

   def edit
      @collection = JSONModel(:collection).find(params[:id], "resolve[]" => "subjects")

      if params[:inline]
         return render :partial=>"collections/edit_inline"
      end

     fetch_collection_tree(@collection)
   end


   def create
     handle_crud(:instance => :collection,
                 :on_invalid => ->(){ render action: "new" },
                 :on_valid => ->(id){ redirect_to(:controller => :collections,
                                                  :action => :edit,
                                                  :id => id) })
   end


   def update
     handle_crud(:instance => :collection,
                 :obj => JSONModel(:collection).find(params[:id],
                                                     "resolve[]" => "subjects"),
                 :on_invalid => ->(){
                   render :partial => "edit_inline"
                 },
                 :on_valid => ->(id){
                   flash[:success] = "Collection Saved"
                   render :partial => "edit_inline"
                 })
   end


   def destroy
  
   end

   def tree
      fetch_collection_tree(JSONModel(:collection).find(params[:id]))
      render :text => @collection_tree.to_json
   end
   
   def update_tree
      begin
         tree = JSONModel(:collection_tree).from_json(params[:tree])
         tree.save(:collection_id=>params[:id])
         render :text=>"Success"
      rescue JSONModel::ValidationException => e
         render :text=>"Error"
      end
   end

   
   private 
   
      def convert_refs_to_ids(tree)
         tree["id"] = JSONModel(:archival_object).id_for(tree["archival_object"])

         tree["children"].each do |child|
         convert_refs_to_ids(child)
         end

         tree
      end
   
      def fetch_collection_tree(collection)
       tree = JSONModel(:collection_tree).find(nil, :collection_id => collection.id)

       @collection_tree = {
         "collection_id" => collection.id,
         "title" => collection.title,
         "children" => tree ? [convert_refs_to_ids(tree.to_hash)] : []
       }
      end
  
end
