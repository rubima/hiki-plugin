def rename_label
	'改名'
end

module Hiki
	class Rename < Command
		private
		
		def rename_label
			'改名'
		end
		
		def old_name_label
			'古い名前: '
		end
		
		def new_name_label
			'新しい名前: '
		end
		
		def failed_label
			'改名に失敗しました。'
		end
		
		def alias_label
			'新しい名前に別名を付ける'
		end
	end
end
