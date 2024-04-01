Dialog.create("");
Dialog.addMessage("Creating HDR image of Total Solar Eclipse", 30, "Red");
Dialog.addMessage("                    (c) 2024 - Jan Wisniewski                ", 24, "Red");
Dialog.addMessage("*          *          *          *          *          *          *", 30, "Red");
Dialog.addMessage("This software requires ImageJ (download it from fiji.sc)", 20, "Blue");
Dialog.addMessage("Use IRIS (http://www.astrosurf.com/buil/iris-software.html)\n to convert Raw images into RGB (16-bit channels) stack\n(Menu: Digital photo --> Decode RAW files... --> RGB option)", 20, "Blue");
Dialog.addMessage("Number them in order of increasing exposure(starting with 100,\ne.g. Image_100, Image_101, Image_103, etc.)", 20, "Blue");
Dialog.addMessage("Increase memory available to ImageJ \n(Edit > Options > Memory & Threads...)", 20, "Blue");
Dialog.addMessage("Eclipsed Sun should be centered in the frame\n(float or crop image if needed)", 20, "Blue");
Dialog.addMessage("*   Click OK if above steps are completed   *", 20, "Red");
Dialog.show();

Dialog.create("");
Dialog.addMessage("Process images\n  starting with:", 20, "Blue");
Dialog.addRadioButtonGroup("", newArray("Converted cfa files", "Aligned images", "Initial masks", "Differential masks", "Masked images", "Combined images", "Rotated images", "Divided images", "Multiplied images", "Scaled + color"), 10, 1, "Converted cfa files");
Dialog.addCheckbox("Display all operations (slow)", false);
Dialog.show();
stp=Dialog.getRadioButton();
dsp=Dialog.getCheckbox();
print(dsp);
prc=getDirectory("Create / Select Dedicated Processing Folder");

//*****************************************************************************************************************

if(stp=="Converted cfa files") {myDir1 = prc + "1_CONVERTED"  + File.separator;
myDir2 = prc + "2_ALIGNED"  + File.separator;
	File.makeDirectory(myDir2);
chk=File.exists(prc + "1_CONVERTED");
if(chk==0) {File.makeDirectory(myDir1);	
conv=getDirectory("Which folder contains images converted with IRIS");
lsc=getFileList(conv);
for (i = 0; i < lsc.length; i++) {File.copy(conv + lsc[i], myDir1 + lsc[i]);	}	}	

lst1=getFileList(myDir1);
for (i = 0; i < lst1.length; i++) {open(myDir1 + lst1[i]);
ttl=File.nameWithoutExtension;
rename("x");
if(i==0) {mdn=getValue("Median");
bck=round(mdn - sqrt(mdn));
Dialog.create("");
Dialog.addRadioButtonGroup("How would you like to align images?", newArray("Use Moon disk", "Field star", "No alignment"), 3, 1, "Use Moon disk");
Dialog.addNumber("Enter background value (image median is shown)", bck);
Dialog.show();
ali=Dialog.getRadioButton();
bgd=Dialog.getNumber();		}

run("Subtract...", "value=[bgd] stack");

if(ali!="No alignment") {run("Z Project...", "projection=[Sum Slices]");
rename("SUM");
run("Log");

if(ali=="Use Moon disk") {if(dsp==0) {setBatchMode(true);     }
run("Enhance Contrast", "saturated=0.35");
run("Variance...", "radius=20");
setAutoThreshold("Default dark");
run("Threshold...");
setOption("BlackBackground", false);
run("Convert to Mask");
getDimensions(width, height, channels, slices, frames);
doWand(width/2, height/2);
if(i==0) {BXS=getValue("BX");
BYS=getValue("BY");
BXX=getValue("Width");
BYY=getValue("Height");
x0=BXS+BXX/2;
y0=BYS+BYY/2;
run("Select None");			}
else {IXS=getValue("BX");
IYS=getValue("BY");
IXX=getValue("Width");
IYY=getValue("Height");
dX=x0-IXS-IXX/2;
dY=y0-IYS-IYY/2;		}
close("SUM");		}

if(ali=="Field star") {run("Enhance Contrast", "saturated=5");
if(i==0) {setTool("rectangle");
waitForUser("Find alignment star and draw a box around it");
BXS=getValue("BX");
BYS=getValue("BY");
BXX=getValue("Width");
BYY=getValue("Height");	
if(dsp==0) {setBatchMode(true);     }		}
else {makeRectangle(BXS, BYS, BXX, BYY);		}
run("Duplicate...", " ");
resetMinAndMax;
run("Enhance Contrast", "saturated=0.35");
run("Gaussian Blur...", "sigma=2");
prm=(i+1)*0.2;
run("Find Maxima...", "prominence=[prm] strict output=List");
if(i==0) {x0=getResult("X");
					y0=getResult("Y");		}	
else {xS=getResult("X");
	yS=getResult("Y");	
	dX=x0-xS;
	dY=y0-yS;		}
close("SUM-1");
close("SUM");		}

if(i>0) {run("Translate...", "x=[dX] y=[dY] interpolation=None stack");		}		}	

saveAs("Tif", myDir2 + ttl);			
close(ttl + ".tif"); 				}
close("Results");
stp="Aligned images";
setBatchMode(false);

if(ali!="No alignment") {print("* All images aligned on the field star");		}
else {print("WARNING! Images were not aligned");			}		} 

//*****************************************************************************************************************

if(stp=="Aligned images") {myDir2 = prc + "2_ALIGNED"  + File.separator;
myDir3 = prc + "3_INITIAL_MASKS"  + File.separator;
	File.makeDirectory(myDir3);

lst2=getFileList(myDir2);
open(myDir2 + lst2[lst2.length-1]);  
setSlice(2);
mv=getValue("Max");

Dialog.create("");
Dialog.addMessage("            Mask threshold", 20, "Blue");
Dialog.addNumber("Set upper brightness limit for mask creation", 2*mv/3, 0, 6, "ADUs");
Dialog.addMessage("(2/3 of saturation level shown)");
Dialog.show();
uplm=Dialog.getNumber();

close(lst2[lst2.length-1]); 
	
for (i = 0; i < lst2.length; i++) {open(myDir2 + lst2[i]);
ttl=File.nameWithoutExtension;
setSlice(2);

if(i==0) {run("Duplicate...", "title=x");
setAutoThreshold("Default dark");
run("Threshold...");
waitForUser("Adjust to selesct continuous thin ring");
setOption("BlackBackground", false);
run("Convert to Mask"); 
if(dsp==0) {setBatchMode(true);     }
run("Options...", "iterations=5 count=3 pad do=Close");
getDimensions(width, height, channels, slices, frames);
doWand(width/2, height/2);
run("Clear Outside");
run("Select None");
run("Grays");
run("Invert");
saveAs("Tif", myDir3 + ttl);
rename("D");		}

else {run("Duplicate...", "title=G");
setAutoThreshold("Default dark");
setThreshold(uplm, 1000000000000000000000000000000.0000);
run("Convert to Mask");   
run("Fill Holes");
run("Grays");
imageCalculator("Add create", "D","G");  
saveAs("Tif", myDir3 + ttl);  
close(ttl + ".tif");
close("G");		}
close(lst2[i]);		}	
setBatchMode(false);
close("D");
stp="Initial masks";
close("Threshold");
print("* Masks created from individual images");		} 

//*****************************************************************************************************************

if(stp=="Initial masks") {myDir3 = prc + "3_INITIAL_MASKS"  + File.separator;
myDir4 = prc + "4_DIFFERENTIAL_MASKS"  + File.separator;
	File.makeDirectory(myDir4); 
lst3=getFileList(myDir3);
if(dsp==0) {setBatchMode(true);     }
chku=0;
for (i = 0; i < lst3.length-1; i++) {u=lst3.length-1-i;
open(myDir3 + lst3[u]);
ttl=File.nameWithoutExtension;
rename("A");  
if(chku==0) {run("Duplicate...", " "); 
run("Invert");
run("32-bit");
run("Divide...", "value=255");
setMinAndMax(0, 1);
saveAs("Tif", myDir4 + ttl);
close(ttl+".tif");
chku=1;			}
open(myDir3 + lst3[u-1]);
ttw=File.nameWithoutExtension;
rename("B"); 
if(u>1) {imageCalculator("Difference create", "A","B");
close("A");
close("B");				}
else {selectWindow("B");
getDimensions(width, height, channels, slices, frames);
doWand(width/2, height/2);
run("Enlarge...", "enlarge=-3");
run("Select None");
close("B");
selectWindow("A");
run("Restore Selection");
run("Clear");
run("Select None");		}
run("Grays");
run("32-bit");
run("Divide...", "value=255");
setMinAndMax(0, 1);
saveAs("Tif", myDir4 + ttw); 
close(ttw + ".tif");		}
setBatchMode(false);		
stp="Differential masks";
print("* Differential masks assembled");		} 

//*****************************************************************************************************************

if(stp=="Differential masks") {if(dsp==0) {setBatchMode(true);     }
myDir5 = prc + "5_MASKED_IMAGES"  + File.separator;
	File.makeDirectory(myDir5);
myDir2 = prc + "2_ALIGNED"  + File.separator;
myDir4 = prc + "4_DIFFERENTIAL_MASKS"  + File.separator;

open(myDir2);
rename("ALG");
run("Make Substack...", "slices=1-39-3");
rename("R");
selectWindow("ALG");
run("Make Substack...", "slices=2-39-3");
rename("G");
selectWindow("ALG");
run("Make Substack...", "slices=3-39-3");
rename("B");
close("ALG");
open(myDir4);
rename("MSK");
setSlice(1);
getDimensions(width, height, channels, slices, frames);
doWand(width/2, height/2);		
run("Invert", "slice");
run("Select None");

imageCalculator("Multiply create 32-bit stack", "R","MSK");
saveAs("Tif", myDir5 + "RED");
close("R");
imageCalculator("Multiply create 32-bit stack", "G","MSK");
saveAs("Tif", myDir5 + "GREEN");
close("G");
imageCalculator("Multiply create 32-bit stack", "B","MSK");
saveAs("Tif", myDir5 + "BLUE");
close("B");
close("MSK");

imageCalculator("Add create 32-bit stack", "RED.tif","GREEN.tif");
imageCalculator("Add create 32-bit stack", "Result of RED.tif","BLUE.tif");
saveAs("Tif", myDir5 + "LUM"); 
for (i = 0; i < 5; i++) {close();		}

setBatchMode(false);
stp="Masked images";	
print("* Images masked with differential masks");		}  

//*****************************************************************************************************************

if(stp=="Masked images") {myDir6 = prc + "6_COMBINED"  + File.separator;
	File.makeDirectory(myDir6);
myDir5 = prc + "5_MASKED_IMAGES"  + File.separator;
myDir3 = prc + "3_INITIAL_MASKS"  + File.separator;

par=File.exists(prc + "Parameters.csv");
if(par==1) {if(dsp==0) {setBatchMode(true);     }		}
open(myDir5 + "LUM.tif"); 
slc=nSlices;
if(par==0) {title1 = "Parameters"; 
title2 = "["+title1+"]"; 
f=title2; 
run("New... ", "name="+title2+" type=Table"); 
print(f,"\\Headings:Layer\tFactor");
nbr=1.0;
for (m = 0; m < slc-1; m++) {for (p = 0; p < 25; p++) {selectWindow("LUM.tif");	
if(p==0) {if(m==0) {setSlice(slc-m);
		run("Duplicate...", "title=A");
		selectWindow("LUM.tif");			}
setSlice(slc-m-1);
run("Duplicate...", "title=B");		}
else {selectWindow("B");		}
run("Duplicate...", "title=L");
run("Multiply...", "value=nbr");
imageCalculator("Max create 32-bit", "A", "L");
rename("M");
close("L");	
setTool("rotrect");
if(p==0) {if(m==0) {waitForUser("Select area to inspect");
run("Select None");		}		}
run("Restore Selection"); 
if(p==0) {if(m>0) {waitForUser("Adjust area to inspect");		}		}
run("Duplicate...", "title=I");
run("Unsharp Mask...", "radius=10 mask=0.90");

Dialog.createNonBlocking("");
Dialog.addNumber("     Adjust merge factor:", nbr);
Dialog.addMessage("*               or               *");
Dialog.addCheckbox("Check this box if images merge smoothly", false);
Dialog.show();
nbr=Dialog.getNumber();
smt=Dialog.getCheckbox();
close("I");
if(smt==0) {close("M");		}
else {print(f,m+1 + "\t" + nbr);
close("A");
close("B");
selectWindow("M");
run("Select None");
rename("A");
p=25;		}		}		}
saveAs("Tif", myDir6 + "LUM");
close();
close();
selectWindow("Parameters");
saveAs("Text", prc + "Parameters.csv");
close("Parameters");
if(dsp==0) {setBatchMode(true);     }		}		

if(par==1) {Table.open(prc + "Parameters.csv");
for (m = 0; m < slc-1; m++) {nbr=getResult("Factor", m);
selectWindow("LUM.tif");
if(m==0) {setSlice(slc-m);
		run("Duplicate...", "title=A");
		selectWindow("LUM.tif");			}
setSlice(slc-m-1);
run("Duplicate...", "title=B");
run("Multiply...", "value=nbr");
imageCalculator("Max create 32-bit", "A", "B");
rename("M");
close("A");
close("B");
selectWindow("M");
rename("A");		} 
saveAs("Tif", myDir6 + "LUM");
close();			
close();		
close("Parameters.csv");		}

open(myDir5 + "BLUE.tif");
run("Z Project...", "projection=[Max Intensity]");
run("Macro...", "code=[if(v<1) {v=1; }]");
run("Gaussian Blur...", "sigma=5");
rename("B");
close("BLUE.tif");
open(myDir5 + "GREEN.tif");
run("Z Project...", "projection=[Max Intensity]");
run("Macro...", "code=[if(v<1) {v=1; }]");
run("Gaussian Blur...", "sigma=5");
rename("G");
close("GREEN.tif");
open(myDir5 + "RED.tif");
run("Z Project...", "projection=[Max Intensity]");
run("Macro...", "code=[if(v<1) {v=1; }]");
run("Gaussian Blur...", "sigma=5");
rename("R");
close("RED.tif");
open(myDir5 + "LUM.tif");
run("Z Project...", "projection=[Max Intensity]");
run("Macro...", "code=[if(v<1) {v=1; }]");
run("Gaussian Blur...", "sigma=5");
rename("L");
close("LUM.tif");
imageCalculator("Divide create 32-bit", "B","L");
rename("BLUE");
close("B");
imageCalculator("Divide create 32-bit", "G","L");
rename("GREEN");
close("G");
imageCalculator("Divide create 32-bit", "R","L");
rename("RED");
close("R");
close("L");
open(myDir6 + "LUM.tif");
run("Images to Stack", "use");

lst3=getFileList(myDir3);
open(myDir3 + lst3[0]);
getDimensions(width, height, channels, slices, frames);
doWand(width/2, height/2);
sftx=width/2 - getValue("BX") - getValue("Width")/2;
sfty=height/2 - getValue("BY") - getValue("Height")/2;
run("Select None");
close(lst3[0]);

selectWindow("Stack");
run("Translate...", "x=[sftx] y=[sfty] interpolation=Bicubic stack");
run("Stack to Images");
imlst=getList("image.titles");
for (i = 0; i < imlst.length; i++) {print(imlst[i]);
selectWindow(imlst[i]);
resetMinAndMax;
run("Enhance Contrast", "saturated=0.05");
saveAs("Tif", myDir6 + imlst[i]);
close();	}
stp="Combined images";
setBatchMode(false);
print("* Masked images combined and centered: shif x=", sftx, "   y=", sfty);		}

//*****************************************************************************************************************

if(stp=="Combined images") {myDir6 = prc + "6_COMBINED"  + File.separator;
myDir7 = prc + "7_ROTATED"  + File.separator;
	File.makeDirectory(myDir7);
	
Dialog.create("");
Dialog.addMessage("Rotational blurring to enhance\n           radial details", 20, "Blue");
Dialog.addNumber("Specify rotation step size (degrees)", 0.1);
Dialog.addMessage("Use up to 3 rotatioin ranges (in increasing order)\nTo use 2 ranges, enter 0 in Small\nTo use only 1 range, enter 0 in Midrange as well");
Dialog.addNumber("Small range(degrees)", 2);
Dialog.addNumber("... medium", 5);
Dialog.addNumber("and high", 10);
Dialog.addMessage("");
Dialog.addNumber("To add Gaussian blur, enter radius >0", 3);
Dialog.show();
rstp=Dialog.getNumber();
rota1=Dialog.getNumber();
rota2=Dialog.getNumber();
rota3=Dialog.getNumber();
gblr=Dialog.getNumber();

open(myDir6 + "LUM.tif");
rename("ROT");
rotmax=0.5*rota3/rstp;
for (s = 1; s < rotmax+1; s++) {showProgress(s, rotmax+1);
anga=rstp*(s-0.5);
angb=-anga;
if(dsp==0) {setBatchMode(true);     }	
selectWindow("ROT");
run("Duplicate...", " ");
run("Rotate... ", "angle=anga grid=1 interpolation=Bicubic");	
selectWindow("ROT");
run("Duplicate...", " ");
run("Rotate... ", "angle=angb grid=1 interpolation=Bicubic");	}
close("ROT");
run("Images to Stack", "use");		
if(gblr>0) {run("Gaussian Blur...", "sigma=gblr stack");		}
run("Z Project...", "projection=[Average Intensity]");
run("Add...", "value=1");
saveAs("Tiff", myDir7 + rota3);
close();

if(rota2!=0) {trm=-1+(rota3-rota2)/rstp;
selectWindow("Stack");
lslc=nSlices;
fslc=lslc-trm;
run("Slice Remover", "first=[fslc] last=[lslc] increment=1");
run("Z Project...", "projection=[Average Intensity]");
run("Add...", "value=1");
saveAs("Tiff", myDir7 + rota2);
close();		}

if(rota1!=0) {trm=-1+(rota2-rota1)/rstp;
selectWindow("Stack");
lslc=nSlices;
fslc=lslc-trm;
run("Slice Remover", "first=[fslc] last=[lslc] increment=1");
run("Z Project...", "projection=[Average Intensity]");
run("Add...", "value=1");
saveAs("Tiff", myDir7 + rota1);
close();		}	 
close("Stack");			
setBatchMode(false);
stp="Rotated images";
print("* Blurred by rotation:", rota1, ", ", rota2, " and ", rota3, "degrees", ", in", rstp, "degree steps");		} 

//*****************************************************************************************************************

if(stp=="Rotated images") {myDir6 = prc + "6_COMBINED"  + File.separator;
myDir7 = prc + "7_ROTATED"  + File.separator;
myDir8 = prc + "8_DIVIDED" + File.separator;
	File.makeDirectory(myDir8);
if(dsp==0) {setBatchMode(true);     }
lst7 = getFileList(myDir7);
open(myDir6 + "LUM.tif");
rename("x");
for (j = 0; j < lst7.length; j++) {open(myDir7 + lst7[j]);
ttm=File.nameWithoutExtension;
rename("msk");
imageCalculator("Divide create 32-bit stack", "x","msk"); 
run("Macro...", "code=[if(v<0) {v=0;}]");
run("Macro...", "code=[if(v>5) {v=5;}]");
run("Despeckle");
run("Median...", "radius=2");
setMinAndMax(0.95, 1.05);
saveAs("Tif", myDir8 + ttm);
close(ttm+".tif");	
close("msk");		}
close("x");		
setBatchMode(false);
stp="Divided images";
print("* Images divided by blurred masks");		} 

//*****************************************************************************************************************
if(stp=="Divided images") {myDir6 = prc + "6_COMBINED"  + File.separator;
myDir8 = prc + "8_DIVIDED" + File.separator;
myDir9 = prc + "9_MULTIPLIED" + File.separator;
	File.makeDirectory(myDir9);

Dialog.create("");
Dialog.addMessage("Choose one or more methods\nof rotational unsharp masking\n(listed in order of strength)", 20, "Blue");
Dialog.addCheckbox("Image squared / Blurred", false);
Dialog.addCheckbox("Image cubed / Blurred squared", false);
Dialog.addCheckbox("Image to 4th power / Blurred cubed", false);
Dialog.show();
i2b=Dialog.getCheckbox();
i3b2=Dialog.getCheckbox();
i4b3=Dialog.getCheckbox();
	
if(dsp==0) {setBatchMode(true);     }
open(myDir6 + "LUM.tif");
rename("A");
lst8=getFileList(myDir8);
for (i = 0; i < lst8.length; i++) {open(myDir8+lst8[i]);
ttm=File.nameWithoutExtension;
rename("div");
imageCalculator("Multiply create 32-bit stack", "A","div");
if(i2b==1) {saveAs("Tif", myDir9 + ttm);   }
rename("A2");
imageCalculator("Multiply create 32-bit stack", "A2","div");
if(i3b2==1) {saveAs("Tif", myDir9 + ttm + "_SQ");	}  
rename("A3");
if(i4b3==1) {imageCalculator("Multiply create 32-bit stack", "A3","div");
saveAs("Tif", myDir9 + ttm + "_CB");
close(ttm + "_CB.tif");		}
close("A3");
close("A2");
close("div");		}
close("A");
setBatchMode(false);
stp="Multiplied images";
print("* ... then product multiplied by images");		} 	

//*****************************************************************************************************************

if(stp=="Multiplied images") {myDir9 = prc + "9_MULTIPLIED" + File.separator;
myDir6 = prc + "6_COMBINED" + File.separator;
myDir10 = prc + "10_SCALED" + File.separator;
	File.makeDirectory(myDir10);

lst9=getFileList(myDir9);
for (i = 0; i < lst9.length; i++) {open(myDir9 + lst9[i]);
run("Macro...", "code=[if(v<1) {v=1; }]");
run("Log");
resetMinAndMax;			}
run("Tile");
oim=getList("image.titles");
Dialog.createNonBlocking("");
Dialog.addMessage("Choose images to use in the nest step");
for (j = 0; j < oim.length; j++) {Dialog.addCheckbox(oim[j], false);		}
Dialog.show();
for (j = 0; j < oim.length; j++) {kp=Dialog.getCheckbox();
if(kp==0) {close(oim[j]);		}	}	
run("Cascade");
	
Dialog.create("");
Dialog.addMessage("To apply unsharp mask to LUM\nimage, set values >0", 20, "Blue");
Dialog.addNumber("radius (pixels) =", 7);
Dialog.addNumber("mask weight (0.1-0.9) =", 0.75);
Dialog.addMessage("");
Dialog.addMessage("For local contrast enhancement,\nchange ALL values below to >0:", 20, "Blue");
Dialog.addChoice("block size =", newArray("0", "31", "63", "127"), "63");
Dialog.addChoice("histogram =", newArray("0", "256", "512", "1024"), "512");
Dialog.addNumber("maximum =", 7);
Dialog.show();
unrd=Dialog.getNumber();
unwgt=Dialog.getNumber();
clhbox=Dialog.getChoice();
clhhst=Dialog.getChoice();
clhmax=Dialog.getNumber();
clh=1*clhbox*clhhst*clhmax;

sim=getList("image.titles");
for (k = 0; k < sim.length; k++) {selectWindow(sim[k]);
idx=indexOf(sim[k], ".tif");
ttl=substring(sim[k], 0, idx);
print(ttl);
if(k==0) {setTool("rectangle");
waitForUser("Select crop area");
bx0=getValue("BX");
by0=getValue("BY");
sdx=getValue("Width");
sdy=getValue("Height");
run("Crop");
run("Duplicate...", "title=enh");
setAutoThreshold("Default dark");
run("Threshold...");
waitForUser("Adjust to select thin unbroken ring");
setOption("BlackBackground", false);
run("Convert to Mask");
getDimensions(width, height, channels, slices, frames);
doWand(width/2, height/2);
run("Clear Outside");
run("Select None");		

run("Duplicate...", "title=dsk");
run("Grays");
run("Divide...", "value=255");	
if(dsp==0) {setBatchMode(true);		}		 }
else {makeRectangle(bx0, by0, sdx, sdy);
run("Crop");		}  
selectWindow(sim[k]);
resetMinAndMax;
run("Enhance Contrast", "saturated=0.01");
run("16-bit");
if(unrd>0) {run("Unsharp Mask...", "radius=unrd mask=unwgt");		}
imageCalculator("Multiply create", sim[k], "dsk");
resetMinAndMax;
run("Enhance Contrast", "saturated=0.01");
run("16-bit");
saveAs("Tif", myDir10 + ttl + "_SC"); 

if(clh!=0) {run("Duplicate...", "title=x");
run("Enhance Local Contrast (CLAHE)", "blocksize=63 histogram=512 maximum=7 mask=enh");
imageCalculator("Average create", "x", ttl+"_SC.tif");
imageCalculator("Average create", "Result of x", ttl+"_SC.tif");
saveAs("Tif", myDir10 + ttl + "_LC"); 
close(ttl + "_LC.tif");
close(ttl + "_SC.tif");
close("Result of x");
close("x");		}  
close(ttl + ".tif");		}
if(clh!=0) {close("enh");		}  

setBatchMode(false);

lst6=getFileList(myDir6);
for (h = 0; h < lst6.length; h++) {open(myDir6 + lst6[h]);
tti=File.nameWithoutExtension;
if(tti!="LUM") {makeRectangle(bx0, by0, sdx, sdy);
run("Crop");
imageCalculator("Multiply create", lst6[h], "dsk");
rename(tti + "_A");		}  
close(lst6[h]);			}	
close("dsk");

selectImage("RED_A");
run("Duplicate...", " ");
setAutoThreshold("Default dark");
run("Threshold...");
waitForUser("Adjust to select promimences");
setOption("BlackBackground", true);
run("Convert to Mask");
run("Grays");
run("32-bit");
run("Divide...", "value=255");
setMinAndMax(0, 1);
run("Gaussian Blur...", "sigma=7");
run("Divide...", "value=4");
run("Add...", "value=1");
setMinAndMax(0.00, 1.25); 
imageCalculator("Multiply create", "RED_A","RED_A-1");
rename("R");
close("RED_A");
selectImage("BLUE_A");
imageCalculator("Divide create", "BLUE_A","RED_A-1");
rename("B");
close("BLUE_A");
selectImage("GREEN_A");
imageCalculator("Divide create", "GREEN_A","RED_A-1");
rename("G");
close("GREEN_A");
close("RED_A-1");
run("Merge Channels...", "c1=R c2=G c3=B create");
saveAs("Tif", myDir10 + "COLOR"); 
close("COLOR.tif");					
close("Threshold");
setBatchMode(false);
print("* Enhanced luminosity and color balance images created / Crop rectangle:", bx0, ",", by0, ",", sdx, ",", sdy);		 		
stp="Scaled + color";		}

//*****************************************************************************************************************

if(stp=="Scaled + color") {myDir10 = prc + "10_SCALED" + File.separator;

myDir11 = prc + "11_FINAL" + File.separator;
	File.makeDirectory(myDir11);

lst10=getFileList(myDir10);
for (i = 0; i < lst10.length; i++) {if(lst10[i]!="COLOR.tif") {open(myDir10 + lst10[i]);  }		}
run("Tile"); 
oim=getList("image.titles");
Dialog.createNonBlocking("");
Dialog.addMessage("Choose images to use in making color pictures");
for (j = 0; j < oim.length; j++) {Dialog.addCheckbox(oim[j], false);		}
Dialog.show();
for (j = 0; j < oim.length; j++) {kp=Dialog.getCheckbox();
if(kp==0) {close(oim[j]);		}	}

if(dsp==0) {setBatchMode(true);	}
sim=getList("image.titles"); 
open(myDir10 + "COLOR.tif");
run("Tile");

for (q = 0; q < sim.length; q++) {idx=indexOf(sim[q], ".tif");
ttl=substring(sim[q], 0, idx);
imageCalculator("Multiply create stack", "COLOR.tif", sim[q]);
rename(ttl+"_COLOR");
for (s = 1; s < 4; s++) {setSlice(s);
resetMinAndMax;
if(s!=3) {run("Enhance Contrast", "saturated=0.1");		} 
else {run("Enhance Contrast", "saturated=0.5");		}		}		

saveAs("Tif", myDir11 + ttl+"_COLOR");
run("RGB Color");
saveAs("Tif", myDir11 + ttl + "_RGB");
close(ttl + "COLOR.tif");
close(ttl + "_RGB.tif");		}
ims=nImages;
for (i = 0; i < ims; i++) {close();		}
print("* Color images assembled");			}

selectWindow("Log");
saveAs("Text", prc + "0_Log");
close("Log");
setBatchMode(false);
exit("FINISHED");