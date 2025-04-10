meta:
  id: mdk_sni
  file-extension: sni
  license: Proprietary
  endian: le
  imports: 
    - /media/wav
    
seq:
  - id: archive_length
    type: u4
  
  - id: archive_filename
    type: str
    size: 12
    encoding: ASCII
  
  - id: archive_length_2
    type: u4
  
  - id: number_of_files
    type: u4
  
  - id: files
    type: file_details
    repeat: expr
    repeat-expr: number_of_files
  
types:
  file_details:
    seq:
      - id: filename
        type: str
        size: 12
        encoding: ASCII
      - id: type
        type: u2
      - id: unknown2
        type: u2
      - id: file_offset
        type: u4
      - id: file_length
        type: u4
    instances:
      body:
        pos: file_offset
        size: file_length
        type: wav