//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_tvOS
import XCTest

/// Tests for NetworkError
final class NetworkErrorTests: XCTestCase {

    // MARK: - Factory Method Tests

    func testFromURLErrorCodeTimeout() {
        let error = NetworkError.from(urlErrorCode: -1001)
        XCTAssertEqual(error, .timeout)
    }

    func testFromURLErrorCodeHostNotFound() {
        let error = NetworkError.from(urlErrorCode: -1003)
        XCTAssertEqual(error, .hostNotFound)
    }

    func testFromURLErrorCodeCannotConnect() {
        let error = NetworkError.from(urlErrorCode: -1004)
        XCTAssertEqual(error, .cannotConnect)
    }

    func testFromURLErrorCodeConnectionLost() {
        let error = NetworkError.from(urlErrorCode: -1005)
        XCTAssertEqual(error, .connectionLost)
    }

    func testFromURLErrorCodeNoConnection() {
        let error = NetworkError.from(urlErrorCode: -1009)
        XCTAssertEqual(error, .noConnection)
    }

    func testFromURLErrorCodeSSL() {
        // Test various SSL error codes
        for code in [-1200, -1201, -1202, -1203, -1204, -1205, -1206] {
            let error = NetworkError.from(urlErrorCode: code)
            XCTAssertEqual(error, .sslError, "Expected sslError for code \(code)")
        }
    }

    func testFromURLErrorCodeUnknown() {
        let error = NetworkError.from(urlErrorCode: -9999)
        if case .unknown = error {
            // Expected
        } else {
            XCTFail("Expected unknown error")
        }
    }

    // MARK: - HTTP Status Code Tests

    func testFromHTTPStatusCode400() {
        let error = NetworkError.from(httpStatusCode: 400)
        if case .badRequest = error {
            // Expected
        } else {
            XCTFail("Expected badRequest error")
        }
    }

    func testFromHTTPStatusCode401() {
        let error = NetworkError.from(httpStatusCode: 401)
        XCTAssertEqual(error, .unauthorized)
    }

    func testFromHTTPStatusCode403() {
        let error = NetworkError.from(httpStatusCode: 403)
        XCTAssertEqual(error, .forbidden)
    }

    func testFromHTTPStatusCode404() {
        let error = NetworkError.from(httpStatusCode: 404)
        XCTAssertEqual(error, .notFound)
    }

    func testFromHTTPStatusCode500() {
        let error = NetworkError.from(httpStatusCode: 500)
        if case let .serverError(code, _) = error {
            XCTAssertEqual(code, 500)
        } else {
            XCTFail("Expected serverError")
        }
    }

    func testFromHTTPStatusCode503() {
        let error = NetworkError.from(httpStatusCode: 503, message: "Service Unavailable")
        if case let .serverError(code, message) = error {
            XCTAssertEqual(code, 503)
            XCTAssertEqual(message, "Service Unavailable")
        } else {
            XCTFail("Expected serverError")
        }
    }

    // MARK: - Recoverability Tests

    func testTimeoutIsRecoverable() {
        XCTAssertTrue(NetworkError.timeout.isRecoverable)
    }

    func testConnectionLostIsRecoverable() {
        XCTAssertTrue(NetworkError.connectionLost.isRecoverable)
    }

    func testNoConnectionIsRecoverable() {
        XCTAssertTrue(NetworkError.noConnection.isRecoverable)
    }

    func testUnauthorizedIsNotRecoverable() {
        XCTAssertFalse(NetworkError.unauthorized.isRecoverable)
    }

    func testForbiddenIsNotRecoverable() {
        XCTAssertFalse(NetworkError.forbidden.isRecoverable)
    }

    func testNotFoundIsNotRecoverable() {
        XCTAssertFalse(NetworkError.notFound.isRecoverable)
    }

    // MARK: - Hashable Conformance Tests

    func testErrorsAreHashable() {
        var set = Set<NetworkError>()
        set.insert(.timeout)
        set.insert(.unauthorized)
        set.insert(.timeout) // Duplicate

        XCTAssertEqual(set.count, 2)
    }
}
