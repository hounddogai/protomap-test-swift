import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation assignment.
    final class IsolationAssignmentView {
        var codeText: String
        var label: String
        var category: String
        var minimumText: String
        var ratio: String
        var name: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, label: String, category: String, minimumText: String, ratio: String, name: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.category = category
            self.minimumText = minimumText
            self.ratio = ratio
            self.name = name
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationAssignmentView(_ item: IsolationAssignment) -> IsolationAssignmentView {
        return IsolationAssignmentView(
            codeText: item.code,
            label: item.label,
            category: Kit.Text.truncate(item.category, limit: 80),
            minimumText: String(format: "%.2f", item.minimum),
            ratio: String(format: "%.2f", item.ratio),
            name: Kit.Text.truncate(item.name, limit: 120),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationAssignmentViews(_ items: [IsolationAssignment]) -> [IsolationAssignmentView] {
        var views: [IsolationAssignmentView] = []
        for item in items {
            views.append(toIsolationAssignmentView(item))
        }
        return views
    }

    static func sumIsolationAssignmentView(_ view: IsolationAssignmentView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedMinimum + parsedRatio
    }
}
