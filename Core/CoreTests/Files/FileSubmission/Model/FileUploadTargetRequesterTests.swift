//
// This file is part of Canvas.
// Copyright (C) 2022-present  Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

@testable import Core
import XCTest

class FileUploadTargetRequesterTests: CoreTestCase {
    private let tempFileURL = URL.temporaryDirectory.appendingPathComponent("FileUploadTargetRequesterTests.txt")

    override func setUp() {
        super.setUp()
        FileManager.default.createFile(atPath: tempFileURL.path, contents: "tst".data(using: .utf8), attributes: nil)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempFileURL)
        super.tearDown()
    }

    func testFileUploadTargetSavedToUploadItem() {
        // MARK: - GIVEN
        let submission: FileSubmission = databaseClient.insert()
        submission.courseID = "testCourse"
        submission.assignmentID = "testAssignment"

        let item: FileUploadItem = databaseClient.insert()
        item.localFileURL = tempFileURL
        item.fileSubmission = submission
        item.uploadError = "previousError"

        let body = PostFileUploadTargetRequest.Body(name: "FileUploadTargetRequesterTests.txt", on_duplicate: .rename, parent_folder_path: nil, size: 3)
        let request = PostFileUploadTargetRequest(context: submission.fileUploadContext, body: body)
        api.mock(request, value: FileUploadTarget(upload_url: URL(string: "/test")!, upload_params: ["testKey": "testValue"]))

        let testee = FileUploadTargetRequester(api: api, context: databaseClient, fileUploadItemID: item.objectID)
        let completionEvent = expectation(description: "completion event fire")

        // MARK: - WHEN
        let subscription = testee.requestUploadTarget().sink { completion in
            if case .finished = completion {
                completionEvent.fulfill()
            }
        }

        // MARK: - THEN
        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(item.uploadTarget, FileUploadTarget(upload_url: URL(string: "/test")!, upload_params: ["testKey": "testValue"]))
        XCTAssertNil(item.uploadError)

        subscription.cancel()
    }

    func testFileUploadErrorSaveToUploadItem() {
        // MARK: - GIVEN
        let submission: FileSubmission = databaseClient.insert()
        submission.courseID = "testCourse"
        submission.assignmentID = "testAssignment"

        let item: FileUploadItem = databaseClient.insert()
        item.localFileURL = tempFileURL
        item.fileSubmission = submission
        item.uploadTarget = FileUploadTarget(upload_url: URL(string: "/previous_url")!, upload_params: [:])

        let body = PostFileUploadTargetRequest.Body(name: "FileUploadTargetRequesterTests.txt", on_duplicate: .rename, parent_folder_path: nil, size: 3)
        let request = PostFileUploadTargetRequest(context: submission.fileUploadContext, body: body)
        api.mock(request, value: nil, error: NSError.instructureError("testError"))

        let testee = FileUploadTargetRequester(api: api, context: databaseClient, fileUploadItemID: item.objectID)
        let completionEvent = expectation(description: "completion event fire")

        // MARK: - WHEN
        let subscription = testee.requestUploadTarget().sink { completion in
            if case .failure(let error) = completion {
                XCTAssertEqual(error as! String, "testError")
                completionEvent.fulfill()
            }
        }

        // MARK: - THEN
        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(item.uploadError, "testError")
        XCTAssertNil(item.uploadTarget)

        subscription.cancel()
    }
}
