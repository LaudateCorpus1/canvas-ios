//
// This file is part of Canvas.
// Copyright (C) 2019-present  Instructure, Inc.
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

import XCTest
import TestsFoundation
@testable import Core

class NotificationsListTests: CanvasUITests {
    override var user: UITestUser? { return nil }

    func testNotificationItemsDisplayed() {
        mockDataRequest(URLRequest(url: URL(string: "https://canvas.instructure.com/api/v1/users/self/profile?per_page=50")!), data: """
        {"id":1,"name":"Bob","short_name":"Bob","sortable_name":"Bob","locale":"en"}
        """.data(using: .utf8))
        mockEncodableRequest("/api/v1/users/self/activity_stream?per_page=99", value: [
            APIActivity.make(),
            APIActivity.make(id: "2", title: "Another Notification"),
        ], response: HTTPURLResponse(url: URL(string: "/")!, statusCode: 200, httpVersion: nil, headerFields: nil))

        logIn(domain: "canvas.instructure.com", token: "t")
        TabBar.notificationsTab.tap()

        app.find(labelContaining: "Assignment Created").waitToExist()
        app.find(labelContaining: "Another Notification").waitToExist()
    }
}