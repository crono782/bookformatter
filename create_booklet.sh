#!/bin/sh

SOURCEPDF=$1

TOTALPAGES=$(pdfinfo $SOURCEPDF|grep ^Pages|awk '{print $2}')
FOLIOS_PS=$2
PAPERSIZE=${3:-letterpaper}

if [ "$SOURCEPDF" = "" ] || [ "$FOLIOS_PS" = "" ]; then
	echo "You must provide a source PDF and desired folios per signature"
	exit
fi

LEAVES_PS=$(($FOLIOS_PS*2))
PAGES_PS=$(($LEAVES_PS*2))
NUMBERSIGS=$(($TOTALPAGES/$PAGES_PS))

echo TOTALPAGES: $TOTALPAGES
echo FOLIOS PER SIG: $FOLIOS_PS
echo LEAVES PER SIG: $LEAVES_PS
echo PAGES_PER SIG: $PAGES_PS
echo NUMBER SIGS: $NUMBERSIGS

LOWER=0
UPPER=0
UL=0
UR=0
LL=0
LR=0
PDFCOUNT=0

for i in $(seq 1 $NUMBERSIGS); do
	echo -- SIGNATURE: $i --

	LOWER=$(($UPPER+1))
	UPPER=$(($LOWER+$PAGES_PS-1))
	echo LOWER: $LOWER UPPER: $UPPER
	for f in $(seq 1 $FOLIOS_PS); do
		if [ `expr $f % 2` -eq 0 ]; then
			EVENODD="EVEN"
		else
			EVENODD="ODD"
		fi
		echo PRINT PAGE $f $EVENODD
		if [ $f -eq 1 ]; then
			UL=$UPPER
			UR=$LOWER
			LL=$(($UL-2))
			LR=$(($UR+2))
		elif [ "$EVENODD" = "EVEN" ]; then
			ULTMP=$UL
			URTMP=$UR
			UL=$(($URTMP+1))
			UR=$(($ULTMP-1))
			LL=$(($UL+2))
			LR=$(($UR-2))
		else
			UL=$(($LR-1))
			UR=$(($LL+1))
			LL=$(($UL-2))
			LR=$(($UR+2))
		fi
		echo UL: $UL UR: $UR
		echo LL: $LL LR: $LR
		PDFCOUNT=$(($PDFCOUNT+1))
		if [ $PDFCOUNT -lt 10 ]; then
			PDFNUM="0$PDFCOUNT"
		else
			PDFNUM=$PDFCOUNT
		fi
		pdfjam --nup 2x2 --$PAPERSIZE --frame true $SOURCEPDF "$UL,$UR,$LL,$LR" --outfile $SOURCEPDF-4UP-SOURCE-$PDFNUM.pdf
	done

done
pdfjam $SOURCEPDF-4UP-SOURCE-* --$PAPERSIZE --outfile $SOURCEPDF-4UP-JOINED.pdf
rm -f $SOURCEPDF-4UP-SOURCE-*
exit
