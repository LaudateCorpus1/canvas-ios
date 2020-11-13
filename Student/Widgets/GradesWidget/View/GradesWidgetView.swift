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

import WidgetKit
import SwiftUI

struct GradesWidgetView: View {
    private let model: GradeModel
    private var firstGrade: GradeItem? { model.assignmentGrades.first ?? model.courseGrades.first }
    @Environment(\.widgetFamily)
    private var family
    private let lineCountByFamily: [WidgetFamily: Int] = [
        .systemMedium: 2,
        .systemLarge: 5,
    ]

    var body: some View {
        if let firstGrade = firstGrade {
            switch family {
            case .systemLarge, .systemMedium:
                MediumLargeGradesView(model: model, lineCount: lineCountByFamily[family]!)
            default:
                SmallGradeView(gradeItem: firstGrade)
            }
        } else if model.isLoggedIn {
            EmptyView(title: Text("Grades"), message: Text("No Grades To Display"))
        } else {
            EmptyView(title: Text("Grades"), message: Text("Please log in via the application"))
        }
    }

    init(model: GradeModel) {
        self.model = model
    }
}

#if DEBUG
struct GradesWidgetPreviews: PreviewProvider {
    static var previews: some View {
        let data = GradeModel.make()
        GradesWidgetView(model: data).previewContext(WidgetPreviewContext(family: .systemSmall))
        GradesWidgetView(model: data).previewContext(WidgetPreviewContext(family: .systemMedium))
        GradesWidgetView(model: data).previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
#endif
