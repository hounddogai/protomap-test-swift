import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual discharge plan profile.
    final class ManualDischargePlanProfileView {
        var codeText: String
        var title: String
        var ceiling: String
        var procedureCodeText: String
        var source: String
        var capacity: String
        var notesText: String
        var statusLabel: String

        init(codeText: String, title: String, ceiling: String, procedureCodeText: String, source: String, capacity: String, notesText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ceiling = ceiling
            self.procedureCodeText = procedureCodeText
            self.source = source
            self.capacity = capacity
            self.notesText = notesText
            self.statusLabel = statusLabel
        }
    }

    static func toManualDischargePlanProfileView(_ item: ManualDischargePlanProfile) -> ManualDischargePlanProfileView {
        return ManualDischargePlanProfileView(
            codeText: item.code,
            title: item.title,
            ceiling: String(format: "%.2f", item.ceiling),
            procedureCodeText: item.procedureCode,
            source: Kit.Text.truncate(item.source, limit: 80),
            capacity: String(item.capacity),
            notesText: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualDischargePlanProfileViews(_ items: [ManualDischargePlanProfile]) -> [ManualDischargePlanProfileView] {
        var views: [ManualDischargePlanProfileView] = []
        for item in items {
            views.append(toManualDischargePlanProfileView(item))
        }
        return views
    }

    static func sumManualDischargePlanProfileView(_ view: ManualDischargePlanProfileView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedCeiling + Double(parsedCapacity)
    }
}
