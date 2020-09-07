Utilities authorInitials: 'wx'.


FileList compile: (
	(FileList sourceCodeAt: #defaultEncoderFor:)
		copyReplaceAll: 'MacRomanTextConverter' with: 'UTF8TextConverter'
) classified: 'private'.

MultiByteFileStream removeSelector: #fileIn.

FileStream class compile: '
fileIn: fullName
	^ (MultiByteFileStream readOnlyFileNamed: fullName) converter: UTF8TextConverter new; fileIn
' classified: '*System-Files'.

TTFontReader compile: (
	(TTFontReader sourceCodeAt: #decodeCmapFmtTable:)
		copyReplaceAll: 'cmap at: i + 1 put: code' with: 'cmap at: i + 1  put: code \\ 65536'
) classified: 'private'.

(ChangeSet named: 'HomeProject') clear.


Preferences disable: #swapMouseButtons.

(TTCFontDescription addFromTTFile:  '..\fonts\wqy-microhei.ttc') do: [:each | TTCFont newTextStyleFromTT: each].

(UserInterfaceTheme named: 'Trim (dark)')
	set: #standardButtonFont to: (TTCFont family: 'WenQuanYiMicroHei' size: 15);
	set: #standardCodeFont to: (TTCFont family: 'WenQuanYiMicroHeiMono' size: 15);
	set: #standardListFont to: (TTCFont family: 'WenQuanYiMicroHei' size: 15);
	set: #standardMenuFont to: (TTCFont family: 'WenQuanYiMicroHei' size: 15);
	set: #standardSystemFont to: (TTCFont family: 'WenQuanYiMicroHei' size: 15);
	set: #windowTitleFont to: (TTCFont family: 'WenQuanYiMicroHei' size: 15);
apply.


[SystemWindow deleteTopWindow] valueSupplyingAnswer: true.

Smalltalk snapshot: true andQuit: true.
