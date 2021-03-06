# Included in WriteVTK.jl

function vtk_multiblock(filename_noext::AbstractString)
    # Initialise VTK multiblock file (extension .vtm).
    # filename_noext: filename without the extension (.vtm).

    xvtm = XMLDocument()
    xroot = create_root(xvtm, "VTKFile")
    set_attribute(xroot, "type", "vtkMultiBlockDataSet")
    set_attribute(xroot, "version", "1.0")
    if IS_LITTLE_ENDIAN
        set_attribute(xroot, "byte_order", "LittleEndian")
    else
        set_attribute(xroot, "byte_order", "BigEndian")
    end
    xMBDS = new_child(xroot, "vtkMultiBlockDataSet")

    return MultiblockFile(xvtm, string(filename_noext, ".vtm"))
end


function vtk_grid(vtm::MultiblockFile, griddata...; kwargs...)
    # Creates new dataset file that is added to the multiblock file.
    # "griddata" can be any combination of arrays that define a VTK grid.
    path_base = splitext(vtm.path)[1]
    vtkFilename_noext = @sprintf("%s.z%02d", path_base, 1 + length(vtm.blocks))
    vtk = vtk_grid(vtkFilename_noext, griddata...; kwargs...)
    multiblock_add_block(vtm, vtk)
    return vtk::DatasetFile
end


function vtk_save(vtm::MultiblockFile)
    # Saves VTK multiblock file (.vtm).
    # Also saves the contained block files (vtm.blocks) recursively.
    outfiles = [vtm.path]::Vector{UTF8String}
    for vtk in vtm.blocks
        push!(outfiles, vtk_save(vtk)...)
    end
    save_file(vtm.xdoc, vtm.path)
    return outfiles::Vector{UTF8String}
end


function multiblock_add_block(vtm::MultiblockFile, vtk::VTKFile)
    # Add VTK file as a new block to a multiblock file.

    # Find vtkMultiBlockDataSet node
    xroot = root(vtm.xdoc)
    xMBDS = find_element(xroot, "vtkMultiBlockDataSet")

    # Block node
    xBlock = new_child(xMBDS, "Block")
    nblock = length(vtm.blocks)
    set_attribute(xBlock, "index", "$nblock")

    # DataSet node
    # This splits the filename and the directory name.
    fname = splitdir(vtk.path)[2]

    xDataSet = new_child(xBlock, "DataSet")
    set_attribute(xDataSet, "index", "0")
    set_attribute(xDataSet, "file",  fname)

    # Add the block file to vtm.
    push!(vtm.blocks, vtk)

    return
end

