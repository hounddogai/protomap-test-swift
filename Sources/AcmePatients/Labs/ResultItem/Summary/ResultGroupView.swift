import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result group.
    final class ResultGroupView {
        var code: String
        var titleText: String
        var pinned: String
        var visibleText: String
        var approved: String
        var maximum: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, titleText: String, pinned: String, visibleText: String, approved: String, maximum: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.pinned = pinned
            self.visibleText = visibleText
            self.approved = approved
            self.maximum = maximum
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toResultGroupView(_ item: ResultGroup) -> ResultGroupView {
        return ResultGroupView(
            code: item.code,
            titleText: item.title,
            pinned: "\(item.pinned)",
            visibleText: "\(item.visible)",
            approved: "\(item.approved)",
            maximum: String(format: "%.2f", item.maximum),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultGroupViews(_ items: [ResultGroup]) -> [ResultGroupView] {
        var views: [ResultGroupView] = []
        for item in items {
            views.append(toResultGroupView(item))
        }
        return views
    }

    static func sumResultGroupView(_ view: ResultGroupView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedMaximum + Double(parsedVisitMinutes)
    }
}
