import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:future_button/future_button.dart';

class PlannedException implements Exception {}

const waitDuration = Duration(milliseconds: 150);
const animationDuration = Duration(milliseconds: 50);
const resultIndicatorDuration = Duration(milliseconds: 150);

final progressIndicatorBuilders = <WidgetBuilder>[
  defaultMaterialProgressIndicatorBuilder,
  defaultCupertinoProgressIndicatorBuilder,
];

final successIndicatorBuilder = defaultSuccessResultIndicatorBuilder;
final failureIndicatorBuilder = defaultFailureResultIndicatorBuilder;

typedef FutureButtonBuilder = Widget Function({
  required FutureCallback onPressed,
  WidgetBuilder? progressIndicatorBuilder,
  WidgetBuilder? successIndicatorBuilder,
  WidgetBuilder? failureIndicatorBuilder,
  bool showResult,
  Widget child,
  ProgressIndicatorLocation? progressIndicatorLocation,
});

Future<void> waitForAndFail() async {
  await Future.delayed(waitDuration);
  throw PlannedException();
}

Future<void> waitFor() {
  return Future.delayed(waitDuration);
}

Future<void> waitForAnimation() {
  return Future.delayed(animationDuration);
}

Future<void> waitForResultIndicator() {
  return Future.delayed(resultIndicatorDuration);
}

Future<void> testButtonWithArgs(
  WidgetTester tester, {
  List<ProgressIndicatorLocation> progressIndicatorLocations =
      ProgressIndicatorLocation.values,
  FutureButtonBuilder? builder,
  FutureCallback? onTap,
  bool shouldError = false,
  bool shouldShowResultIndicator = false,
}) async {
  for (final progressIndicatorLocation in progressIndicatorLocations) {
    for (final progressIndicatorBuilder in progressIndicatorBuilders) {
      final child = Container();
      // final progressIndicator = progressIndicatorBuilder();
      // final successIndicator = progressIndicatorBuilder();
      // final failureIndicator = progressIndicatorBuilder();

      final widget = builder!(
        onPressed: onTap ?? () async {},
        progressIndicatorBuilder: (_) => progressIndicatorBuilder(_),
        successIndicatorBuilder: (_) => progressIndicatorBuilder(_),
        failureIndicatorBuilder: (_) => progressIndicatorBuilder(_),
        progressIndicatorLocation: progressIndicatorLocation,
        showResult: shouldShowResultIndicator,
        child: child,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: widget)),
        ),
      );

      final state = tester.state<GenericFutureButtonState>(
        find.byWidget(widget),
      );

      expect(find.byWidget(widget), findsOneWidget);
      expect(find.byWidget(child), findsOneWidget);
      // expect(find.byWidget(progressIndicator), findsNothing);

      expect(state.isLoading, equals(false));
      expect(state.isEnabled, equals(onTap != null));

      if (onTap != null) {
        await tester.runAsync(() async {
          await tester.tap(find.byWidget(widget));
          await tester.pump();

          expect(
            find.byWidget(child),
            progressIndicatorLocation == ProgressIndicatorLocation.center
                ? findsNothing
                : findsOneWidget,
          );

          // expect(find.byWidget(progressIndicator), findsOneWidget);

          expect(state.isLoading, equals(true));
          expect(state.isEnabled, equals(false));

          await waitFor();
          await tester.pump();
        });

        if (shouldShowResultIndicator) {
          expect(find.byWidget(widget), findsOneWidget);

          if (progressIndicatorLocation == ProgressIndicatorLocation.center) {
            expect(find.byWidget(child), findsNothing);
          } else {
            expect(find.byWidget(child), findsOneWidget);
          }

          // expect(find.byWidget(progressIndicator), findsNothing);
          // expect(
          //     find.byWidget(shouldError ? failureIndicator : successIndicator),
          //     findsOneWidget);

          expect(state.isLoading, equals(true));
          expect(state.isEnabled, equals(false));

          await tester.runAsync(() async {
            await waitForResultIndicator();
            await tester.pump();
          });

          expect(find.byWidget(widget), findsOneWidget);
          expect(find.byWidget(child), findsOneWidget);
          // expect(find.byWidget(successIndicator), findsNothing);
          // expect(find.byWidget(failureIndicator), findsNothing);
          // expect(find.byWidget(progressIndicator), findsNothing);

          expect(state.isLoading, equals(false));
          expect(state.isEnabled, equals(true));
        } else {
          expect(find.byWidget(widget), findsOneWidget);
          expect(find.byWidget(child), findsOneWidget);
          // expect(find.byWidget(progressIndicator), findsNothing);

          expect(state.isLoading, equals(false));
          expect(state.isEnabled, equals(true));
        }
      }
    }
  }
}

void testButton({
  String? name,
  FutureButtonBuilder? builder,
  List<ProgressIndicatorLocation> progressIndicatorLocations =
      ProgressIndicatorLocation.values,
}) {
  testWidgets(
    'Test normal $name',
    (tester) async {
      await testButtonWithArgs(
        tester,
        builder: builder,
        onTap: waitFor,
        progressIndicatorLocations: progressIndicatorLocations,
      );
    },
  );

  testWidgets(
    'Test disabled $name',
    (tester) async {
      await testButtonWithArgs(
        tester,
        builder: builder,
        onTap: null,
        progressIndicatorLocations: progressIndicatorLocations,
      );
    },
  );

  testWidgets(
    'Test success result $name',
    (tester) async {
      await testButtonWithArgs(
        tester,
        builder: builder,
        onTap: waitFor,
        progressIndicatorLocations: progressIndicatorLocations,
        shouldError: false,
        shouldShowResultIndicator: true,
      );
    },
  );

  testWidgets(
    'Test failure result $name',
    (tester) async {
      await testButtonWithArgs(
        tester,
        builder: builder,
        onTap: waitForAndFail,
        progressIndicatorLocations: progressIndicatorLocations,
        shouldError: true,
        shouldShowResultIndicator: true,
      );
    },
  );
}

void main() {
  testButton(
    name: 'FutureCupertinoButton',
    builder: ({
      required FutureCallback onPressed,
      WidgetBuilder? progressIndicatorBuilder,
      WidgetBuilder? successIndicatorBuilder,
      WidgetBuilder? failureIndicatorBuilder,
      bool showResult = true,
      Widget child = const SizedBox(),
      ProgressIndicatorLocation? progressIndicatorLocation,
    }) {
      return FutureCupertinoButton(
        onPressed: onPressed,
        progressIndicatorLocation: progressIndicatorLocation,
        progressIndicatorBuilder: progressIndicatorBuilder,
        successIndicatorBuilder: successIndicatorBuilder,
        failureIndicatorBuilder: failureIndicatorBuilder,
        showResult: showResult,
        animationDuration: animationDuration,
        animateTransitions: false,
        resultIndicatorDuration: resultIndicatorDuration,
        child: child,
      );
    },
  );

  testButton(
    name: 'FutureCupertinoButton.filled',
    builder: ({
      required FutureCallback onPressed,
      WidgetBuilder? progressIndicatorBuilder,
      WidgetBuilder? successIndicatorBuilder,
      WidgetBuilder? failureIndicatorBuilder,
      bool showResult = true,
      Widget child = const SizedBox(),
      ProgressIndicatorLocation? progressIndicatorLocation,
    }) {
      return FutureCupertinoButton.filled(
        onPressed: onPressed,
        progressIndicatorLocation: progressIndicatorLocation,
        progressIndicatorBuilder: progressIndicatorBuilder,
        successIndicatorBuilder: successIndicatorBuilder,
        failureIndicatorBuilder: failureIndicatorBuilder,
        showResult: showResult,
        animationDuration: animationDuration,
        animateTransitions: false,
        resultIndicatorDuration: resultIndicatorDuration,
        child: child,
      );
    },
  );

  testButton(
    name: 'FutureFlatButton',
    builder: ({
      required FutureCallback onPressed,
      WidgetBuilder? progressIndicatorBuilder,
      WidgetBuilder? successIndicatorBuilder,
      WidgetBuilder? failureIndicatorBuilder,
      bool showResult = true,
      Widget child = const SizedBox(),
      ProgressIndicatorLocation? progressIndicatorLocation,
    }) {
      return FutureFlatButton(
        onPressed: onPressed,
        progressIndicatorLocation: progressIndicatorLocation,
        progressIndicatorBuilder: progressIndicatorBuilder,
        successIndicatorBuilder: successIndicatorBuilder,
        failureIndicatorBuilder: failureIndicatorBuilder,
        showResult: showResult,
        animationDuration: animationDuration,
        animateTransitions: false,
        resultIndicatorDuration: resultIndicatorDuration,
        child: child,
      );
    },
  );

  testButton(
    name: 'FutureFlatButton.icon',
    builder: ({
      required FutureCallback onPressed,
      WidgetBuilder? progressIndicatorBuilder,
      WidgetBuilder? successIndicatorBuilder,
      WidgetBuilder? failureIndicatorBuilder,
      bool showResult = true,
      Widget child = const SizedBox(),
      ProgressIndicatorLocation? progressIndicatorLocation,
    }) {
      return FutureFlatButton.icon(
        icon: Icon(Icons.star),
        label: child,
        onPressed: onPressed,
        progressIndicatorLocation: progressIndicatorLocation,
        progressIndicatorBuilder: progressIndicatorBuilder,
        successIndicatorBuilder: successIndicatorBuilder,
        failureIndicatorBuilder: failureIndicatorBuilder,
        showResult: showResult,
        animationDuration: animationDuration,
        animateTransitions: false,
        resultIndicatorDuration: resultIndicatorDuration,
      );
    },
  );
  testButton(
    name: 'FutureIconButton',
    progressIndicatorLocations: [ProgressIndicatorLocation.center],
    builder: ({
      required FutureCallback onPressed,
      WidgetBuilder? progressIndicatorBuilder,
      WidgetBuilder? successIndicatorBuilder,
      WidgetBuilder? failureIndicatorBuilder,
      bool showResult = true,
      Widget child = const SizedBox(),
      ProgressIndicatorLocation? progressIndicatorLocation,
    }) {
      return FutureIconButton(
        icon: child,
        onPressed: onPressed,
        progressIndicatorBuilder: progressIndicatorBuilder,
        successIndicatorBuilder: successIndicatorBuilder,
        failureIndicatorBuilder: failureIndicatorBuilder,
        showResult: showResult,
        animationDuration: animationDuration,
        animateTransitions: false,
        resultIndicatorDuration: resultIndicatorDuration,
      );
    },
  );

  testButton(
    name: 'FutureOutlineButton',
    builder: ({
      required FutureCallback onPressed,
      WidgetBuilder? progressIndicatorBuilder,
      WidgetBuilder? successIndicatorBuilder,
      WidgetBuilder? failureIndicatorBuilder,
      bool showResult = true,
      Widget child = const SizedBox(),
      ProgressIndicatorLocation? progressIndicatorLocation,
    }) {
      return FutureOutlineButton(
        onPressed: onPressed,
        progressIndicatorLocation: progressIndicatorLocation,
        progressIndicatorBuilder: progressIndicatorBuilder,
        successIndicatorBuilder: successIndicatorBuilder,
        failureIndicatorBuilder: failureIndicatorBuilder,
        showResult: showResult,
        animationDuration: animationDuration,
        animateTransitions: false,
        resultIndicatorDuration: resultIndicatorDuration,
        child: child,
      );
    },
  );

  testButton(
    name: 'FutureOutlineButton.icon',
    builder: ({
      required FutureCallback onPressed,
      WidgetBuilder? progressIndicatorBuilder,
      WidgetBuilder? successIndicatorBuilder,
      WidgetBuilder? failureIndicatorBuilder,
      bool showResult = true,
      Widget child = const SizedBox(),
      ProgressIndicatorLocation? progressIndicatorLocation,
    }) {
      return FutureOutlineButton.icon(
        icon: Icon(Icons.star),
        label: child,
        onPressed: onPressed,
        progressIndicatorLocation: progressIndicatorLocation,
        progressIndicatorBuilder: progressIndicatorBuilder,
        successIndicatorBuilder: successIndicatorBuilder,
        failureIndicatorBuilder: failureIndicatorBuilder,
        showResult: showResult,
        animationDuration: animationDuration,
        animateTransitions: false,
        resultIndicatorDuration: resultIndicatorDuration,
      );
    },
  );

  testButton(
    name: 'FutureRaisedButton',
    builder: ({
      required FutureCallback onPressed,
      WidgetBuilder? progressIndicatorBuilder,
      WidgetBuilder? successIndicatorBuilder,
      WidgetBuilder? failureIndicatorBuilder,
      bool showResult = true,
      Widget child = const SizedBox(),
      ProgressIndicatorLocation? progressIndicatorLocation,
    }) {
      return FutureRaisedButton(
        onPressed: onPressed,
        progressIndicatorLocation: progressIndicatorLocation,
        progressIndicatorBuilder: progressIndicatorBuilder,
        successIndicatorBuilder: successIndicatorBuilder,
        failureIndicatorBuilder: failureIndicatorBuilder,
        showResult: showResult,
        animationDuration: animationDuration,
        animateTransitions: false,
        resultIndicatorDuration: resultIndicatorDuration,
        child: child,
      );
    },
  );

  testButton(
    name: 'FutureRaisedButton.icon',
    builder: ({
      required FutureCallback onPressed,
      WidgetBuilder? progressIndicatorBuilder,
      WidgetBuilder? successIndicatorBuilder,
      WidgetBuilder? failureIndicatorBuilder,
      bool showResult = true,
      Widget child = const SizedBox(),
      ProgressIndicatorLocation? progressIndicatorLocation,
    }) {
      return FutureRaisedButton.icon(
        icon: Icon(Icons.star),
        label: child,
        onPressed: onPressed,
        progressIndicatorLocation: progressIndicatorLocation,
        progressIndicatorBuilder: progressIndicatorBuilder,
        successIndicatorBuilder: successIndicatorBuilder,
        failureIndicatorBuilder: failureIndicatorBuilder,
        showResult: showResult,
        animationDuration: animationDuration,
        animateTransitions: false,
        resultIndicatorDuration: resultIndicatorDuration,
      );
    },
  );
}
