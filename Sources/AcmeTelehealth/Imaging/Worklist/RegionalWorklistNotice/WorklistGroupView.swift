import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist group.
    final class WorklistGroupView {
        var codeText: String
        var title: String
        var priority: String
        var unit: String
        var specialty: String
        var ownerIDText: String
        var payer: String
        var statusLabel: String

        init(codeText: String, title: String, priority: String, unit: String, specialty: String, ownerIDText: String, payer: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.priority = priority
            self.unit = unit
            self.specialty = specialty
            self.ownerIDText = ownerIDText
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistGroupView(_ item: WorklistGroup) -> WorklistGroupView {
        return WorklistGroupView(
            codeText: item.code,
            title: item.title,
            priority: String(item.priority),
            unit: Kit.Text.truncate(item.unit, limit: 120),
            specialty: item.specialty,
            ownerIDText: item.ownerID,
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistGroupViews(_ items: [WorklistGroup]) -> [WorklistGroupView] {
        var views: [WorklistGroupView] = []
        for item in items {
            views.append(toWorklistGroupView(item))
        }
        return views
    }

    static func sumWorklistGroupView(_ view: WorklistGroupView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
