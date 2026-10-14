import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional courier window.
    final class RegionalCourierWindowView {
        var code: String
        var title: String
        var contactEmailText: String
        var priorityText: String
        var visible: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, title: String, contactEmailText: String, priorityText: String, visible: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.contactEmailText = contactEmailText
            self.priorityText = priorityText
            self.visible = visible
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCourierWindowView(_ item: RegionalCourierWindow) -> RegionalCourierWindowView {
        return RegionalCourierWindowView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            contactEmailText: item.contactEmail,
            priorityText: String(item.priority),
            visible: "\(item.visible)",
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCourierWindowViews(_ items: [RegionalCourierWindow]) -> [RegionalCourierWindowView] {
        var views: [RegionalCourierWindowView] = []
        for item in items {
            views.append(toRegionalCourierWindowView(item))
        }
        return views
    }

    static func sumRegionalCourierWindowView(_ view: RegionalCourierWindowView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
