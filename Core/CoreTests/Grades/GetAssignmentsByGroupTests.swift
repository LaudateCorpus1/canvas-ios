//
// This file is part of Canvas.
// Copyright (C) 2020-present  Instructure, Inc.
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
@testable import Core
import TestsFoundation

class GetAssignmentsByGroupTests: CoreTestCase {
    func testProperties() {
        let useCase = GetAssignmentsByGroup(courseID: "1", gradingPeriodID: "2")
        XCTAssertEqual(useCase.cacheKey, "courses/1/assignment_groups?grading_period_id=2")
        XCTAssertEqual(useCase.request.courseID, "1")
        XCTAssertEqual(useCase.scope.predicate, NSPredicate(key: #keyPath(Assignment.assignmentGroup.courseID), equals: "1"))
    }

    func testWrite() {
        let useCase = GetAssignmentsByGroup(courseID: "1", gradingPeriodID: "2")
        useCase.write(response: [.make()], urlResponse: nil, to: databaseClient)
        XCTAssertEqual((databaseClient.fetch() as [AssignmentGroup]).count, 1)
        useCase.reset(context: databaseClient)
        XCTAssertEqual((databaseClient.fetch() as [AssignmentGroup]).count, 0)
    }

    func testInvalidSectionOrderException() {
        let groups: [APIAssignmentGroup] = [
            .make(id: "9732", name: "Test Assignment Group", position: 1, assignments: [APIAssignment.make(id: "63603", name: "File Upload", position: 1, assignment_group_id: "9732")]),
            .make(id: "9734", name: "Middle Group", position: 2, assignments: [APIAssignment.make(id: "63604", name: "File Upload 2", position: 1, assignment_group_id: "9734")]),
            .make(id: "9733", name: "Test Assignment Group", position: 3, assignments: [APIAssignment.make(id: "63606", name: "File Upload 3", position: 1, assignment_group_id: "9733")]),
        ]

        let getAssignmentGroupsUseCase = GetAssignmentsByGroup(courseID: "20783")
        getAssignmentGroupsUseCase.write(response: groups, urlResponse: nil, to: databaseClient)

        // Shouldn't trigger assertionFailure in Store.init with error: Error Domain=NSCocoaErrorDomain Code=134060 "A Core Data error occurred." UserInfo={reason=The fetched object at index 2 has an out of order section name 'Middle Group. Objects must be sorted by section name'}
        _ = environment.subscribe(getAssignmentGroupsUseCase)
    }
}
