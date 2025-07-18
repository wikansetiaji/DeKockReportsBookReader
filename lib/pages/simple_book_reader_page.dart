import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bookfx/bookfx.dart';
import 'package:de_kock_reports_reader/service/size_config.dart';

class SimpleBookReaderPage extends StatefulWidget {
  SimpleBookReaderPage({super.key});

  final numberOfPage = 31;
  final List<String> bookIds = ["dutch", "indonesian", "english"];

  @override
  State<SimpleBookReaderPage> createState() => _SimpleBookReaderPageState();
}

class _SimpleBookReaderPageState extends State<SimpleBookReaderPage>
    with TickerProviderStateMixin {
  late BookController bookController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  double? imgAspectRatio;
  bool isLoading = true;
  Size? firstImageSize;
  int currentPageIndex = 0;
  late int totalPages; // Total number of display pages
  final TransformationController _transformationController =
      TransformationController();
  double _scale = 1.0;
  bool _isZoomed = false;
  double _mediaWidth = 0;
  double _mediaHeight = 0;
  bool _isNavigating = false; // cater bookfx bug
  String bookId = "dutch";

  String selectedLanguage = 'Dutch (Original)';

  final List<String> languages = ['Dutch (Original)', 'English', 'Bahasa'];

  @override
  void initState() {
    super.initState();
    bookController = BookController();

    // Calculate total pages: 1 for first page (blank + first image) + remaining pages paired
    totalPages = 1 + ((widget.numberOfPage - 1) / 2).ceil();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      _transformationController.value = _animation!.value;
    });

    _loadFirstImageAspectRatio();
  }

  Future<void> _loadFirstImageAspectRatio() async {
    try {
      final ByteData data = await rootBundle.load('assets/$bookId/0.webp');
      final Uint8List bytes = data.buffer.asUint8List();
      final Image image = Image.memory(bytes);
      final completer = Completer<Size>();

      image.image
          .resolve(const ImageConfiguration())
          .addListener(
            ImageStreamListener(
              (ImageInfo info, bool _) {
                if (!completer.isCompleted) {
                  completer.complete(
                    Size(
                      info.image.width.toDouble(),
                      info.image.height.toDouble(),
                    ),
                  );
                }
              },
              onError: (Object error, StackTrace? stackTrace) {
                if (!completer.isCompleted) {
                  completer.completeError(error, stackTrace);
                }
              },
            ),
          );

      final Size size = await completer.future;
      if (mounted) {
        setState(() {
          firstImageSize = size;
          // Adjust aspect ratio for dual page layout (2 images side by side)
          imgAspectRatio = (size.width * 2) / size.height;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          imgAspectRatio = 2; // Default to 2:1 ratio for dual page
          isLoading = false;
        });
      }
    }
  }

  void _handleZoomReset() {
    final resetMatrix = Matrix4.identity();
    _animateTo(resetMatrix);
    setState(() {
      _scale = 1.0;
      _isZoomed = false;
    });
  }

  void _handleDoubleTap(BuildContext context, TapDownDetails details) {
    final position = details.localPosition;

    if (_isZoomed) {
      _handleZoomReset();
    } else {
      final scale = 2.0;

      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);

      final zoomed =
          Matrix4.identity()
            ..translate(x, y)
            ..scale(scale);

      _animateTo(zoomed);

      setState(() {
        _scale = scale;
        _isZoomed = true;
      });
    }
  }

  void _animateTo(Matrix4 target) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward(from: 0);
  }

  void goToNextPage() {
    if (_isNavigating) return; // cater bookfx bug
    if (currentPageIndex + 1 < totalPages) {
      bookController.next();
      setState(() {
        _isNavigating = true;
      });
      Future.delayed(const Duration(milliseconds: 800)).then((val) {
        setState(() {
          _isNavigating = false;
        });
      });
      if (_isZoomed) _handleZoomReset();
    }
  }

  void goToPreviousPage() {
    if (_isNavigating) return; // cater bookfx bug
    if (currentPageIndex > 0) {
      bookController.last();
      setState(() {
        _isNavigating = true;
      });
      Future.delayed(const Duration(milliseconds: 800)).then((val) {
        setState(() {
          currentPageIndex -= 1;
          _isNavigating = false;
        });
      });
      if (_isZoomed) _handleZoomReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Color(0xFF282828),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                const SizedBox(height: 20),
                SizedBox(height: 40.sc),
                Expanded(
                  flex: 43,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0.sc),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.sc),
                      child: GestureDetector(
                        onDoubleTapDown:
                            (details) => _handleDoubleTap(context, details),
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 3.0,
                          panEnabled: _isZoomed,
                          scaleEnabled: true,
                          boundaryMargin: EdgeInsets.all(20.sc),
                          onInteractionUpdate: (details) {
                            final newScale =
                                _transformationController.value
                                    .getMaxScaleOnAxis();
                            setState(() {
                              _scale = newScale;
                              _isZoomed = newScale != 1.0;
                            });
                          },
                          child: Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 40.0.sc,
                                    vertical: 0.0.sc,
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final screenSize = constraints.biggest;
                                      final maxHeight = screenSize.height;
                                      final maxWidth = screenSize.width;

                                      double bookWidth = min(
                                        maxWidth,
                                        maxHeight * imgAspectRatio!,
                                      );
                                      double bookHeight =
                                          bookWidth / imgAspectRatio!;

                                      if (bookHeight > maxHeight) {
                                        bookHeight = maxHeight;
                                        bookWidth =
                                            bookHeight * imgAspectRatio!;
                                      }

                                      _mediaWidth = screenSize.width;
                                      _mediaHeight = screenSize.height;

                                      return Stack(
                                        children: [
                                          Center(
                                            child: SizedBox(
                                              width: bookWidth,
                                              height: bookHeight,
                                              child: AbsorbPointer(
                                                absorbing: _isZoomed,
                                                child: BookFx(
                                                  currentBgColor: Colors.white,
                                                  size: Size(
                                                    bookWidth,
                                                    bookHeight,
                                                  ),
                                                  pageCount: totalPages,
                                                  currentPage:
                                                      (index) => _buildBookPage(
                                                        index,
                                                        bookWidth,
                                                        bookHeight,
                                                      ),
                                                  nextPage:
                                                      (index) => _buildBookPage(
                                                        index,
                                                        bookWidth,
                                                        bookHeight,
                                                      ),
                                                  controller: bookController,
                                                  nextCallBack: (index) {
                                                    setState(() {
                                                      currentPageIndex =
                                                          index - 1;
                                                    });
                                                  },
                                                  lastCallBack: (index) {
                                                    if (index > 0) {
                                                      setState(() {
                                                        currentPageIndex =
                                                            index - 1;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.sc),
                Row(
                  children: [
                    Spacer(),
                    dropdownWithoutAnimation(),
                    SizedBox(width: 20.sc),
                    Text(
                      '${(_scale * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontFamily: 'PublicSans',
                        color: Color(0xFF969696),
                        fontSize: 16.sc,
                      ),
                    ),
                    if (_isZoomed)
                      ElevatedButton(
                        onPressed: _handleZoomReset,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.all(14.sc),
                          backgroundColor: Color.fromARGB(255, 85, 85, 85),
                          foregroundColor: Colors.white,
                        ),
                        child: Icon(Icons.zoom_out, size: 24.sc),
                      ),
                    if (!_isZoomed)
                      ElevatedButton(
                        onPressed: () {
                          final scale = 2.0;
                          final zoomed =
                              Matrix4.identity()
                                ..translate(
                                  _mediaWidth / 2 * -1,
                                  _mediaHeight / 2 * -1,
                                )
                                ..scale(scale);
                          _animateTo(zoomed);
                          setState(() {
                            _scale = scale;
                            _isZoomed = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.all(14.sc),
                          backgroundColor: Color.fromARGB(255, 85, 85, 85),
                          foregroundColor: Colors.white,
                        ),
                        child: Icon(Icons.zoom_in, size: 24.sc),
                      ),
                    SizedBox(width: 40.sc),
                    _buildNavButton(
                      context,
                      icon: Icons.chevron_left,
                      onPressed: goToPreviousPage,
                      enabled: currentPageIndex > 0 && !_isNavigating,
                    ),
                    SizedBox(width: 10.sc),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.sc),
                      child: Container(
                        color: Color.fromARGB(255, 85, 85, 85),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.sc,
                          vertical: 10.sc,
                        ),
                        child: Text(
                          '${currentPageIndex + 1} / $totalPages',
                          style: TextStyle(
                            fontFamily: 'PublicSans',
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 16.sc,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.sc),
                    _buildNavButton(
                      context,
                      icon: Icons.chevron_right,
                      onPressed: goToNextPage,
                      enabled: currentPageIndex + 1 < totalPages,
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: 20.sc),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookPage(int pageIndex, double width, double height) {
    // Calculate individual image dimensions (each takes half the width)
    final double imageWidth = width / 2;
    final double imageHeight = height;

    if (pageIndex == 0) {
      // First page: blank left side, first image on right
      return SizedBox(
        key: ValueKey(pageIndex),
        width: width,
        height: height,
        child: Row(
          children: [
            // Left side: blank
            SizedBox(
              width: imageWidth,
              height: imageHeight,
              child: Container(color: const Color(0xFF282828)),
            ),
            // Right side: first image (index 0)
            SizedBox(
              width: imageWidth,
              height: imageHeight,
              child: Image.asset('assets/$bookId/0.webp', fit: BoxFit.cover),
            ),
          ],
        ),
      );
    } else {
      // For subsequent pages: calculate actual image indices
      // Page 1 shows images 1,2 | Page 2 shows images 3,4 | etc.
      final int leftImageIndex = (pageIndex - 1) * 2 + 1;
      final int rightImageIndex = (pageIndex - 1) * 2 + 2;

      return SizedBox(
        key: ValueKey(pageIndex),
        width: width,
        height: height,
        child: Row(
          children: [
            // Left image
            SizedBox(
              width: imageWidth,
              height: imageHeight,
              child:
                  leftImageIndex < widget.numberOfPage
                      ? Image.asset(
                        'assets/$bookId/$leftImageIndex.webp',
                        fit: BoxFit.cover,
                      )
                      : Container(color: const Color(0xFF282828)),
            ),
            // Right image
            SizedBox(
              width: imageWidth,
              height: imageHeight,
              child:
                  rightImageIndex < widget.numberOfPage
                      ? Image.asset(
                        'assets/$bookId/$rightImageIndex.webp',
                        fit: BoxFit.cover,
                      )
                      : Container(color: const Color(0xFF282828)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: EdgeInsets.all(16.sc),
        backgroundColor: Color.fromARGB(255, 85, 85, 85),
        foregroundColor: Colors.white,
      ),
      child: Icon(icon, size: 24.sc),
    );
  }

  Widget dropdownWithoutAnimation() {
    return SizedBox(
      height: 40.sc,
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 85, 85, 85),
          borderRadius: BorderRadius.circular(
            10.sc,
          ), // Optional: for rounded corners
        ),
        child: Theme(
          data: ThemeData(
            textTheme: TextTheme(
              bodyMedium: TextStyle(
                color: Colors.white,
                fontSize: 16.sc,
                fontFamily: 'PublicSans',
              ),
            ),
            // Disable splash and highlight effects
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              padding: EdgeInsets.symmetric(horizontal: 8.sc, vertical: 0.sc),
              value: selectedLanguage,
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              iconSize: 0.sc,
              elevation: 0,
              dropdownColor: Colors.grey[700],
              onChanged: (String? newValue) {
                setState(() {
                  selectedLanguage = newValue!;

                  if (newValue == 'Dutch (Original)') {
                    bookId = 'dutch';
                  } else if (newValue == 'English') {
                    bookId = 'english';
                  } else if (newValue == 'Bahasa') {
                    bookId = 'indonesian';
                  }
                });
              },
              items:
                  languages.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.sc,
                          vertical: 8.sc,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.translate,
                              color: Colors.white,
                              size: 20.sc,
                            ),
                            SizedBox(width: 12.sc),
                            Text(
                              value,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sc,
                                fontFamily: 'PublicSans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
