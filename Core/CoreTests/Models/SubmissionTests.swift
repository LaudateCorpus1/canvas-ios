//
// This file is part of Canvas.
// Copyright (C) 2018-present  Instructure, Inc.
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

import Foundation
import XCTest
@testable import Core

class SubmissionTests: CoreTestCase {
    func testProperties() {
        let submission = Submission.make()

        submission.excused = nil
        XCTAssertNil(submission.excused)
        submission.excused = true
        XCTAssertEqual(submission.excused, true)

        submission.latePolicyStatus = nil
        XCTAssertNil(submission.latePolicyStatus)
        submission.latePolicyStatus = .late
        XCTAssertEqual(submission.latePolicyStatus, .late)

        submission.pointsDeducted = nil
        XCTAssertNil(submission.pointsDeducted)
        submission.pointsDeducted = 5
        XCTAssertEqual(submission.pointsDeducted, 5)

        submission.score = nil
        XCTAssertNil(submission.score)
        submission.score = 10
        XCTAssertEqual(submission.score, 10)

        submission.type = nil
        XCTAssertNil(submission.type)
        submission.type = .online_upload
        XCTAssertEqual(submission.type, .online_upload)

        submission.workflowState = .submitted
        XCTAssertEqual(submission.workflowState, .submitted)
        submission.workflowStateRaw = "bogus"
        XCTAssertEqual(submission.workflowState, .unsubmitted)

        submission.discussionEntries = [
            DiscussionEntry.make(from: .make(id: "2")),
            DiscussionEntry.make(from: .make(id: "1")),
        ]
        XCTAssertEqual(submission.discussionEntriesOrdered.first?.id, "1")

        let date = Date(timeIntervalSinceNow: 0)
        submission.gradedAt = nil
        XCTAssertNil(submission.gradedAt)
        submission.gradedAt = date
        XCTAssertEqual(submission.gradedAt, date)
    }

    func testMediaSubmission() {
        let submission = Submission.make(from: .make(media_comment: .make()))
        XCTAssertNotNil(submission.mediaComment)
    }

    func testIcon() {
        let submission = Submission.make()
        let map: [SubmissionType: UIImage.InstIconName] = [
            .basic_lti_launch: .lti,
            .external_tool: .lti,
            .discussion_topic: .discussion,
            .online_quiz: .quiz,
            .online_text_entry: .text,
            .online_url: .link,
        ]
        for (type, icon) in map {
            submission.type = type
            XCTAssertEqual(submission.icon, UIImage.icon(icon))
        }
        submission.type = .media_recording
        submission.mediaComment = MediaComment.make(from: .make(media_type: .audio))
        XCTAssertEqual(submission.icon, UIImage.icon(.audio))
        submission.mediaComment?.mediaType = .video
        XCTAssertEqual(submission.icon, UIImage.icon(.video))

        submission.type = .online_upload
        submission.attachments = Set([ File.make(from: .make(mime_class: "pdf")) ])
        XCTAssertEqual(submission.icon, UIImage.icon(.pdf))

        submission.type = .on_paper
        XCTAssertNil(submission.icon)

        submission.type = nil
        XCTAssertNil(submission.icon)
    }

    func testSubtitle() {
        let submission = Submission.make(from: .make(
            body: "<a style=\"stuff\">Text</z>",
            attempt: 1,
            attachments: [ .make(size: 1234) ],
            discussion_entries: [ .make(message: "<p>reply<p>") ],
            url: URL(string: "https://instructure.com")
        ))
        let map: [SubmissionType: String] = [
            .basic_lti_launch: "Attempt 1",
            .external_tool: "Attempt 1",
            .discussion_topic: "reply",
            .online_quiz: "Attempt 1",
            .online_text_entry: "Text",
            .online_url: "https://instructure.com",
        ]
        for (type, subtitle) in map {
            submission.type = type
            XCTAssertEqual(submission.subtitle, subtitle)
        }
        submission.type = .media_recording
        submission.mediaComment = MediaComment.make(from: .make(media_type: .audio))
        XCTAssertEqual(submission.subtitle, "Audio")
        submission.mediaComment?.mediaType = .video
        XCTAssertEqual(submission.subtitle, "Video")

        submission.type = .online_upload
        XCTAssertEqual(submission.subtitle, "1 KB")

        submission.type = .on_paper
        XCTAssertNil(submission.subtitle)

        submission.type = nil
        XCTAssertNil(submission.subtitle)
    }

    func testRubricAssessments() {
        let submission = Submission.make(from: .make(rubric_assessment: [
            "A": .make(),
            "B": .make(),
        ]))
        let assessA = RubricAssessment.make(id: "A")
        let assessB = RubricAssessment.make(id: "B")
        let map = submission.rubricAssessments ?? [:]
        XCTAssertEqual(map[assessA.id], assessA)
        XCTAssertEqual(map[assessB.id], assessB)
    }

    func testSaveRubricAssessmentsOnSubmission() {
        let assessmentItem = APIRubricAssessment.make()
        let item = APISubmission.make(rubric_assessment: ["1": assessmentItem])
        Submission.save(item, in: databaseClient)

        let assessments: [RubricAssessment] = databaseClient.fetch()
        let submissions: [Submission] = databaseClient.fetch()
        XCTAssertEqual(submissions.first?.rubricAssessments?["1"], assessments.first)
    }

    func testSaveCommentAttachments() throws {
        let item = APISubmission.make(
            submission_comments: [
                APISubmissionComment.make(
                    attachments: [
                        APIFile.make(id: "1"),
                        APIFile.make(id: "2"),
                    ]
                ),
            ]
        )
        Submission.save(item, in: databaseClient)
        let submissions: [Submission] = databaseClient.fetch()
        let submission = submissions.first
        XCTAssertNotNil(submission)

        let comments: [SubmissionComment] = databaseClient.fetch()
        let comment = comments.first
        XCTAssertNotNil(comment)
        XCTAssertNotNil(comment?.submissionID)
        XCTAssertEqual(comment?.submissionID, submission?.id)
        let fileIDs = comment?.attachments?.map { $0.id }
        XCTAssertTrue(fileIDs?.contains("1") == true)
        XCTAssertTrue(fileIDs?.contains("2") == true)
    }

    func testSavesSubmissionHistory() {
        let item = APISubmission.make(
            attempt: 1,
            submission_history: [.make(attempt: 2)]
        )
        Submission.save(item, in: databaseClient)
        let submissions: [Submission] = databaseClient.fetch()
        XCTAssertEqual(submissions.count, 2)
    }

    func testDoesNotSaveSubmissionHistoryWithNilAttempt() {
        let item = APISubmission.make(
            attempt: 1,
            submission_history: [.make(attempt: nil)]
        )
        Submission.save(item, in: databaseClient)
        let submissions: [Submission] = databaseClient.fetch()
        XCTAssertEqual(submissions.count, 1)
    }
}
