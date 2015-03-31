// Copyright (c) 2015, Kirth Gersen. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/* convert from:
  MDLFile.cs - Allegiance MDL files API 
  Copyright (C) Kirth Gersen, 2001-2003.  All rights reserved.
  v 0.95 
  SaveTofile limitation:
    - LOD not supported
    - single group mdl only
    - no 'real' error handling (BinaryWriter exceptions arent handled)
*/

import 'dart:io';

class short {
  //todo
}

class float {
  //todo
}
class ushort {
  //todo
}
class byte {
  //todo
}

class char {
  //todo
}

class uint {
  //todo
}

class BinaryReader {
  File _file;

  short ReadInt16() {
    throw 'NYI';
  }
  ushort ReadUInt16() {
    throw 'NYI';
  }
  int ReadInt32() {
    throw 'NYI';
  }
  uint ReadUInt32() {
    throw 'NYI';
  }
  float ReadSingle() {
    throw 'NYI';
  }
  List<char> ReadChars(int n) {
    throw 'NYI';
  }
  List<byte> ReadBytes(int n) {
    throw 'NYI';
  }

  BinaryReader(this._file) {
    throw 'NYI';
  }
  void Close() {
    throw 'NYI';
  }
}

class MDLL2 {
  String Name;
  int Value;
}

class MDLHeader {
  short s1;
  short s2;
  int nb_tags;
  int l2;
  int l3;
  int l4;
  List<String> TagsNames;
  List<MDLL2> L2Vals;
  List<String> l3names;

  bool ReadHeader(BinaryReader br) {
    s1 = br.ReadInt16();
    s2 = br.ReadInt16();
    nb_tags = br.ReadInt32();
    l2 = br.ReadInt32();
    l3 = br.ReadInt32();
    l4 = br.ReadInt32();
    TagsNames = new List(nb_tags);
    L2Vals = new List(l2);
    l3names = new List(l3);
    return true;
  }
}

class MDLLight //size = 12 float
{
  float red;
  float green;
  float blue;
  float speed; // or time factor
  float posx;
  float posy;
  float posz;
  float todo1; // 1.25 (0 = crash !)
  float todo2; // 0
  float todo3; // 0.1
  float todo4; // 0
  float todo5; // 0.05
  bool Read(BinaryReader br) {
    red = br.ReadSingle();
    green = br.ReadSingle();
    blue = br.ReadSingle();
    speed = br.ReadSingle();
    posx = br.ReadSingle();
    posy = br.ReadSingle();
    posz = br.ReadSingle();
    todo1 = br.ReadSingle();
    todo2 = br.ReadSingle();
    todo3 = br.ReadSingle();
    todo4 = br.ReadSingle();
    todo5 = br.ReadSingle();
    return true;
  }
}

class MDLFrameData // size = name + 9 float
{
  String name;
  float posx;
  float posy;
  float posz;
  float nx;
  float ny;
  float nz;
  float px;
  float py;
  float pz;
  bool Read(BinaryReader br) {
    posx = br.ReadSingle();
    posy = br.ReadSingle();
    posz = br.ReadSingle();
    nx = br.ReadSingle();
    ny = br.ReadSingle();
    nz = br.ReadSingle();
    px = br.ReadSingle();
    py = br.ReadSingle();
    pz = br.ReadSingle();
    return true;
  }
}

class MDLVertice {
  float x;
  float y;
  float z;
  float mx;
  float my;
  float nx;
  float ny;
  float nz;
}
class MDLMesh {
  int nvertex;
  int nfaces;
  List<MDLVertice> vertices;
  List<ushort> faces;
}
//#define MDLImageInitSize 20
class MDLImage {
  int w;
  int h;
  int bw;
  int bh;
  List<byte> undecoded; // 00 F8 00 00 E0 07 00 00 1F 00 00 00 00 00 00 00 00 CC CC CC
  List<byte> bitmap;

  MDLImage(int w1, int h1) {
    w = w1;
    h = h1;
    bw = w1;
    bh = h1;
    bitmap = null;
    undecoded = new List(20);
    //todo: undecoded = {0x00,0xF8,0x00,0x00,0xE0,0x07,0x00,0x00,0x1F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xCC,0xCC,0xCC};
  }
  bool Read(BinaryReader br) {
    w = br.ReadInt32(); // width
    h = br.ReadInt32(); // height
    bw = br.ReadInt32(); // scanwidth = width * 2 (rounded to upper long)
    bh = br.ReadInt32(); // bits per pixel
    undecoded = br.ReadBytes(20);
    int nbits = (bw * h * bh / 16).floor();
    bitmap = br.ReadBytes(nbits);
    return true;
  }
}

class MDLObject {
  MDLType type;
  int nchildren;
  List<MDLObject> childrens;
  MDLMesh mesh;
  float lodval;
  int textidx;
  MDLImage image;
}

enum MDLType { mdl_empty, mdl_mesh, mdl_group, mdl_lod, mdl_image }

/// <summary>
/// MDLFile : object reprensenting a MDL file in memory
/// </summary>
class MDLFile {
  int NumLights;
  List<MDLLight> Lights;
  int NumFrameDatas;
  List<MDLFrameData> FrameDatas;
  MDLObject RootObject;
  String ReadError;
  int NumTextures;
  List<String> Textures;
  float FrameVal;

  MDLFile() {
    NumLights = 0;
    NumFrameDatas = 0;
    NumTextures = 0;
    RootObject.type = MDLType.mdl_empty;
  }
  /// <summary>
  /// Read a binary MDL file
  /// a real mess !
  /// return true on success
  /// </summary>
  /// <param name="sFileName"></param>
  /// <returns></returns>
  bool ReadFromFile(String sFileName) {
    File cf;
    try {
      cf = new File(sFileName);
    } catch (e) {
      return false;
    }
    BinaryReader br = new BinaryReader(cf);
    uint cookie = br.ReadUInt32();
    if (cookie != 0xDEBADF00) {
      br.Close();
      //cf.Close();
      return false;
    }
    MDLHeader header = new MDLHeader();
    if (!header.ReadHeader(br)) {
      br.Close();
      //cf.Close();
      return false;
    }
    NumTextures = 0;
    for (int i = 0; i < header.nb_tags; i++) {
      String tag = ParseString(br);
      header.TagsNames[i] = tag;
      if ((tag != "model") && (tag != "effect")) NumTextures++;
    }
    int idx = 0;
    List<int> TexturesIdx = new List(NumTextures);
    if (NumTextures != 0) {
      Textures = new List(NumTextures);
      for (int i = 0; i < header.nb_tags; i++) {
        String tag = header.TagsNames[i];
        if ((tag != "model") && (tag != "effect")) {
          Textures[idx] = tag;
          TexturesIdx[idx] = i;
          idx++;
        }
      }
    }

    // ASSERT(idx==NumTextures);
    for (int i = 0; i < header.l2; i++) {
      int uk1 = br.ReadInt32();
      String tag = ParseString(br);
      header.L2Vals[i].Name = tag;
      header.L2Vals[i].Value = uk1;
    }
    for (int i = 0; i < header.l3; i++) {
      String tag = ParseString(br);
      header.l3names[i] = tag;
    }
    // LOOP LEVEL 3

    int lastText = -1;
    //MDLObject lastObject = new MDLObject();
    List<MDLObject> stackedObjects = new List(500);
    List<int> stack = new List(200);
    int sopos = -1;
    for (int L3 = 0; L3 < header.l3; L3++) {
      int l3val = br.ReadInt32();
      bool cont = true;
      int stackpos = -1;
      // LOOL LEVEL 2
      while (cont) {
        int token = br.ReadInt32();
        switch (token) {
          case 5:
            {
              // start of group
              // push # val
              int nentry = br.ReadInt32();
              stack[++stackpos] = nentry;
              break;
            }
          case 9:
            {
              int l2idx = br.ReadInt32();
              if ((l2idx < 0) || (l2idx > header.l2)) {
                //ReadError.Format("unmatched l2idx = %s",l2idx);
                cont = false;
                break;
              } else {
                String l2type = header.L2Vals[l2idx].Name;
                bool matched = false;
                if (l2type == "MeshGeo") {
                  matched = true;
                  int datatype = br.ReadInt32();
                  if (datatype != 7) {
                    cont = false;
                    break;
                  }
                  MDLMesh mesh = new MDLMesh();
                  mesh.nvertex = br.ReadInt32();
                  mesh.nfaces = br.ReadInt32();
                  mesh.vertices = new List(mesh.nvertex);
                  for (int n = 0; n < mesh.nvertex; n++) {
                    // read vertice
                    MDLVertice vert = new MDLVertice();
                    vert.x = br.ReadSingle();
                    vert.y = br.ReadSingle();
                    ;
                    vert.z = br.ReadSingle();
                    ;
                    vert.mx = br.ReadSingle();
                    ;
                    vert.my = br.ReadSingle();
                    ;
                    vert.nx = br.ReadSingle();
                    ;
                    vert.ny = br.ReadSingle();
                    ;
                    vert.nz = br.ReadSingle();
                    ;
                    mesh.vertices[n] = vert;
                  }
                  mesh.faces = new List(mesh.nfaces);
                  for (int n = 0;
                      n < mesh.nfaces;
                      n++) mesh.faces[n] = br.ReadUInt16();
                  stackedObjects[++sopos] = NewMDLObject();
                  stackedObjects[sopos].mesh = mesh;
                  stackedObjects[sopos].type = MDLType.mdl_mesh;
                }
                if (l2type == "ModifiableNumber") {
                  int six = br.ReadInt32();
                  matched = true;
                }
                if (l2type == "LightsGeo") {
                  matched = true;
                  int datatype = br.ReadInt32();
                  if (datatype != 7) {
                    // ReadError.Format("bad data %d in LightsGeo",datatype);
                    cont = false;
                    break;
                  }
                  if (NumLights != 0) {
                    // ReadError.Format("double ligths!!!");
                    cont = false;
                    break;
                  }
                  int nlite = br.ReadInt32();
                  NumLights = nlite;
                  Lights = new List(nlite);
                  for (int n = 0; n < nlite; n++) {
                    MDLLight lite = new MDLLight();
                    lite.Read(br);
                    Lights[n] = lite;
                  }
                }
                if (l2type == "FrameData") {
                  matched = true;
                  int datatype = br.ReadInt32();
                  if (datatype != 7) {
                    //ReadError.Format("bad data %d in FrameData",datatype);
                    cont = false;
                    break;
                  }
                  if (NumFrameDatas != 0) {
                    // ReadError.Format("double framedata!!!");
                    cont = false;
                    break;
                  }
                  int ndata = br.ReadInt32();
                  NumFrameDatas = ndata;
                  FrameDatas = new List(ndata);
                  for (int n = 0; n < ndata; n++) {
                    MDLFrameData data = new MDLFrameData();
                    data.name = ParseString(br);
                    data.Read(br);
                    FrameDatas[n] = data;
                  }
                }
                if (l2type == "TextureGeo") {
                  matched = true;
                  int six = br.ReadInt32();
                  // ASSERT(lastObject != NULL);
                  stackedObjects[sopos].textidx = lastText;
                }
                if (l2type == "LODGeo") {
                  matched = true;
                  int six = br.ReadInt32();
                  MDLObject lastObject = NewMDLObject();
                  lastObject.type = MDLType.mdl_lod;
                  lastObject.nchildren = stack[stackpos] + 1;
                  lastObject.childrens = new List(lastObject.nchildren);
                  for (int n = 0; n < lastObject.nchildren; n++) {
                    lastObject.childrens[n] = stackedObjects[sopos--];
                  }
                  stackedObjects[++sopos] = lastObject;
                  stackpos--;
                }
                if (l2type == "GroupGeo") {
                  matched = true;
                  int six = br.ReadInt32();
                  MDLObject lastObject = NewMDLObject();
                  lastObject.type = MDLType.mdl_group;
                  lastObject.nchildren = stack[stackpos];
                  lastObject.childrens = new List(lastObject.nchildren);
                  for (int n = 0; n < lastObject.nchildren; n++) {
                    lastObject.childrens[n] = stackedObjects[sopos--];
                  }
                  stackedObjects[++sopos] = lastObject;
                  stackpos--;
                }
                if (l2type == "time") {
                  matched = true;
                  //ReadError.Format("!!time!!"),
                  cont = false;
                  break;
                }
                if (l2type == "ImportImage") {
                  matched = true;
                  cont = false;
                  int datatype = br.ReadInt32();
                  if (datatype != 7) {
                    // ReadError.Format("bad data %d in ImportImage",datatype);
                    cont = false;
                    break;
                  }
                  MDLImage img = new MDLImage(0, 0);
                  img.Read(br);
                  stackedObjects[++sopos] = NewMDLObject();
                  stackedObjects[sopos].image = img;
                  stackedObjects[sopos].type = MDLType.mdl_image;
                  break;
                }
                if (!matched) {
                  for (int n = 0;
                      n < header.nb_tags;
                      n++) if (l2type == header.TagsNames[n]) {
                    matched = true;
                    lastText = -1;
                    for (int p = 0; p < NumTextures; p++) {
                      if (TexturesIdx[p] ==
                          header.L2Vals[l2idx].Value) lastText = p;
                    }
                    // ASSERT(lastText != -1);
                  }
                }
                if (!matched) {
                  //ReadError.Format("unmatched l2type = %s\n",l2type);
                  cont = false;
                  break;
                }
              }
              break;
            }
          case 1:
            {
              float val = br.ReadSingle();
              if (header.l3names[L3] == "frame") {
                FrameVal = val;
              } else {
                // ASSERT(lastObject != NULL);
                stackedObjects[sopos].lodval = val;
              }
              break;
            }
          case 10:
            {
              // handle 10
              break;
            }
          case 0:
            {
              if (stackpos >= 0) {
                //stack[stackpos] -=1;
              } else cont = false;
              break;
            }
          default:
            //ReadError.Format("unknow token = %d\n",token);
            cont = false;
            break;
        } // switch
      } // while(cont)
    } // l3
    RootObject = stackedObjects[sopos];
    br.Close();
    //cf.Close();
    return true;
  }
  /// <summary>
  /// Parse a mdl String (could be optimized)
  /// </summary>
  /// <param name="br"></param>
  /// <returns></returns>
  String ParseString(BinaryReader br) {
    String res = "";
    List<char> data = new List(5);
    data[4] = 0;
    do {
      data = br.ReadChars(4);
      for (int i = 0; i < 4; i++) {
        if (data[i] != '\0') res += data[i].toString();
      }
    } while (data[3] != '\0');
    return res;
  }
  /// <summary>
  /// Construct a new MDLObject
  /// </summary>
  /// <returns></returns>
  MDLObject NewMDLObject() {
    MDLObject o = new MDLObject();
    o.nchildren = 0;
    o.childrens = null;
    o.lodval = 0;
    o.type = MDLType.mdl_empty;
    o.textidx = -1;
    return o;
  }
}
