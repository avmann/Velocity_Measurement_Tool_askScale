/**
  * Velocity Measurement Tool
  * 
  * Measure the velocity of particles in the kymogram of the time series.  The tool allows to create
  * the kymogram. The user can make a segmented line selection and the mean speed for each
  * segment will be measured
  *
  * written 2013 by Volker Baecker (INSERM) at Montpellier RIO Imaging (www.mri.cnrs.fr)
  * uses modified code from www.embl.de/emnet/html/kymograph.html (tsp050706.txt TimeSpacePlot (Kymograph))
  * by J. Rietdorf FMI Basel + A. Seitz EMBL Heidelberg
  * 
  * modified by A. Voelzmann, Manchester University, to auto-measure velocities on multiple predefined rois.
  * ask for image dimensions and allows for stretch factor of the kymographs (if dimensions are stretched) - set to 1 if they are not.
*/

var helpURL = "http://dev.mri.cnrs.fr/projects/imagej-macros/wiki/Velocity_Measurement_Tool";
var Z_PROJECT = true;

macro "Velocity Measurement Help (f1) Action Tool - C037T4d14?"{
   showHelp();
}

macro "Velocity Measurement Help [f1]" {
    showHelp();
}

macro "Kymograph (f2) Action Tool - C037T4d14k" {
    createKymogram();
}

macro "Kymograph create kymogram [f2]" {
    createKymogram();
}


macro "Velocity (f3) Action Tool - C037T4d14v" {
    measureVelocities();
}

macro "Velocity [f3]" {
    measureVelocities();
}

function  check4ROItype(mintype,maxtype,notype) {

	if ((selectionType()<mintype)||(selectionType()>maxtype)||(selectionType()==notype)||(selectionType()==-1)){
		if ((mintype==3)&&(maxtype==7)) exit("select a line ROI");
		if ((mintype==0)&&(maxtype==3)) exit("select an area ROI");
		else exit("select a suitable ROI");
	}
}

function showHelp() {
     run('URL...', 'url='+helpURL);
}

function createKymogram() {
	setBatchMode(true);
	title = getTitle();
	hasSelection = false;
	if (selectionType() != -1) hasSelection=true;
	isHyperstack = Stack.isHyperstack;
	if (isHyperstack) {
		run("Reduce Dimensionality...", "  frames keep");
		if (hasSelection)
			run("Restore Selection");
		tmp = getTitle();
	}
	run("Reslice [/]...", "output=0.000 start=Top avoid");
	slices = nSlices;
	rename("kymogram of " + title);
	if (isHyperstack) {
	 	selectWindow(tmp);
		close();
	}
	selectWindow("kymogram of " + title);
	if (slices>1 && Z_PROJECT) {
		run("Z Project...", "start=1 stop="+slices+" projection=[Max Intensity]");
		selectWindow("kymogram of " + title);
		close();
		selectWindow("MAX_kymogram of " + title);
		rename("kymogram of " + title);
	}
	setBatchMode("exit and display");
}

function measureVelocities() {
// modified from www.embl.de/eamnet/html/kymograph.html (tsp050706.txt TimeSpacePlot (Kymograph))
// will work through the roiManager list and determine velocities and times/distances
// values are given as pixel by pixel

// modification by A. Voelzmann to take kymograph stretching and actual x and time scale into consideration	
	Dialog.create("Title");
	Dialog.addNumber("pixel size", 1);				// ask for pixel scale in um (or other desired unit)
	Dialog.addNumber("time between frames", 1);		// ask for scale in time dimension
	Dialog.addNumber("stretch factor x", 1);		//ask for stretch factors
	Dialog.addNumber("stretch factor y", 2);
	Dialog.show()
	pxsz=Dialog.getNumber();						// save original pixel size
	frmtm=Dialog.getNumber();						// save frame time
	sftrx_=Dialog.getNumber();						// save transformation factor in x
	sftry_=Dialog.getNumber();						// save transformation factor in y (time)
	pxsize=pxsz/sftrx_;								// recalculate pixel size taking stretching into consideration
	frametime=frmtm/sftry_;							// recalculate time interval taking stretching into consideration
	
//	print(frametime);
//	print(pxsize);
	
	run("Clear Results");
	roiManager("Deselect"); 						// clean up roiManager
	rc=roiManager("count");							// number of entries in roiManager
	k=0;											// counting variable when going through results
for (j=0;j<rc;j++){									// go through roi list
//	j=0;

	roiManager("select", j); 

	check4ROItype(3,7,-1);
//	run("Clear Results");
	getSelectionCoordinates(x, y);
	sum_dx=0;
	sum_dy=0;     
	
	for (i=0; i<x.length-1; i++){
		dx_now=abs(x[i+1]-x[i]);
		sum_dx=sum_dx+dx_now;

		dy_now=abs(y[i+1]-y[i]);
			if (dy_now==0)dy_now=1;
		sum_dy=sum_dy+dy_now;
		setResult("comet id", k, j+1);				// add cometID to results (basically element of roi list)
		setResult("segment id", k, i+1);			// segment of varying speed of the comet
		setResult("dy sum", k, sum_dy*frametime);	// scaling time for total kymo path
		setResult("dx sum", k, sum_dx*pxsize);		// scaling distance for total kymo path
		setResult("dy now", k, dy_now*frametime);	// scaling time segment on kymo path
		setResult("dx now", k, dx_now*pxsize);		// scaling distance for segment on kymo path
		setResult("actual speed", k, ((dx_now*pxsize)/(dy_now*frametime)));	// recalculating current speed with scaling factors
		setResult("average speed", k, ((sum_dx*pxsize)/(sum_dy*frametime)));	// recalculating average speed over total kymo path with scaling factors
		k=k+1;										// increasing counter to save results in the right row
	}
	updateResults();
}
}