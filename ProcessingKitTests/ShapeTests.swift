//
//  ShapeTests.swift
//  ProcessingKitTests
//
//  Created by AtsuyaSato on 2018/01/29.
//  Copyright © 2018年 Atsuya Sato. All rights reserved.
//

import XCTest
@testable import ProcessingKit

enum Shape {
    case line(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat)
    case rect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)
    case ellipse(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)
}

class ProcessingViewDelegateShapeSpy: ProcessingViewDelegate {
    private let exception: XCTestExpectation
    private let view: ProcessingView
    private let shape: Shape
    private(set) var context: CGContext?

    init(exception: XCTestExpectation, view: ProcessingView, shape: Shape) {
        self.exception = exception
        self.view = view
        self.shape = shape
    }

    func setup() {
        switch shape {
        case .line(let x1, let y1, let x2, let y2):
            self.view.line(x1, y1, x2, y2)
        case .rect(let x, let y, let width, let height):
            self.view.rect(x, y, width, height)
        case .ellipse(let x, let y, let width, let height):
            self.view.ellipse(x, y, width, height)
        }
        self.record(UIGraphicsGetCurrentContext())
        exception.fulfill()
    }

    private func record(_ arg: CGContext?) {
        self.context = arg
    }
}

extension UIBezierPath {
    open func moveTo(_ point: CGPoint) -> UIBezierPath {
        self.move(to: point)
        return self
    }

    open func addLineTo(_ point: CGPoint) -> UIBezierPath {
        self.addLine(to: point)
        return self
    }

    open func addCurveTo(_ points: (to: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint)) -> UIBezierPath {
        self.addCurve(to: points.to, controlPoint1: points.controlPoint1, controlPoint2: points.controlPoint2)
        return self
    }

    open func closePath() -> UIBezierPath {
        self.close()
        return self
    }
}

class ShapeTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testLine() {
        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                description: "draw line(0, 0, 100, 100)",
                shape: .line(x1: 0, y1: 0, x2: 100, y2: 100),
                expect: .left(
                    UIBezierPath()
                        .moveTo(CGPoint(x: 0, y: 0))
                        .addLineTo(CGPoint(x: 100, y: 100))
                        .cgPath
                )
            ),
            #line: TestCase(
                description: "draw line(50, 50, -50, -50)",
                shape: .line(x1: 50, y1: 50, x2: -50, y2: -50),
                expect: .left(
                    UIBezierPath()
                        .moveTo(CGPoint(x: 50, y: 50))
                        .addLineTo(CGPoint(x: -50, y: -50))
                        .cgPath
                )
            ),
            ]

        check(testCases: testCases)
    }

    func testRect() {
        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                description: "draw rect(0, 0, 50, 50)",
                shape: .rect(x: 0, y: 0, width: 50, height: 50),
                expect: .left(
                    UIBezierPath()
                    .moveTo(CGPoint(x: 0, y: 0))
                    .addLineTo(CGPoint(x: 50, y: 0))
                    .addLineTo(CGPoint(x: 50, y: 50))
                    .addLineTo(CGPoint(x: 0, y: 50))
                    .closePath()
                    .cgPath
                )
            ),
            #line: TestCase(
                description: "draw rect(20, 20, 30, 50)",
                shape: .rect(x: 20, y: 20, width: 30, height: 50),
                expect: .left(
                    UIBezierPath()
                    .moveTo(CGPoint(x: 20, y: 20))
                    .addLineTo(CGPoint(x: 50, y: 20))
                    .addLineTo(CGPoint(x: 50, y: 70))
                    .addLineTo(CGPoint(x: 20, y: 70))
                    .closePath()
                    .cgPath
                )
            ),
        ]

        check(testCases: testCases)
    }

    func testElipse() {
        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                description: "draw ellipse(100, 100, 100, 100)",
                shape: .ellipse(x: 100, y: 100, width: 100, height: 100),
                expect: .right([
                    CGPoint(x: 150, y: 100),
                    CGPoint(x: 100, y: 150),
                    CGPoint(x: 50, y: 100),
                    CGPoint(x: 100, y: 50),
                    ]
                )
            ),
            #line: TestCase(
                description: "draw ellipse(0, 0, 100, 100)",
                shape: .ellipse(x: 0, y: 0, width: 100, height: 100),
                expect: .right([
                    CGPoint(x: 50, y: 0),
                    CGPoint(x: 0, y: 50),
                    CGPoint(x: -50, y: 0),
                    CGPoint(x: 0, y: -50),
                    ]
                )
            ),
            ]

        check(testCases: testCases)
    }

    func check(testCases: [UInt: TestCase]) {
        _ = testCases.map { (line, testCase) in
            let view = ProcessingView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

            let transformDelegateSpy = ProcessingViewDelegateShapeSpy(
                exception: expectation(description: testCase.description),
                view: view,
                shape: testCase.shape
            )

            view.delegate = transformDelegateSpy
            waitForExpectations(timeout: 100)

            let actual = transformDelegateSpy.context?.path
            let expected = testCase.expect

            switch expected {
            case .left(let path):
                XCTAssertEqual(actual, path, String(line))
            case .right(let points):
                for point in points {
                    XCTAssertTrue(actual?.contains(point) ?? false, String(line))
                }
            }
        }
    }

    enum Either<T, U> {
        case left(T)
        case right(U)
    }

    struct TestCase {
        let description: String
        let shape: Shape
        let expect: Either<CGPath, [CGPoint]>
    }
}
