import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a strict task entry.
    final class StrictTaskEntryView {
        var code: String
        var labelText: String
        var activeText: String
        var procedureCode: String
        var approved: String
        var copayText: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, labelText: String, activeText: String, procedureCode: String, approved: String, copayText: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.activeText = activeText
            self.procedureCode = procedureCode
            self.approved = approved
            self.copayText = copayText
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictTaskEntryView(_ item: StrictTaskEntry) -> StrictTaskEntryView {
        return StrictTaskEntryView(
            code: item.code,
            labelText: item.label,
            activeText: "\(item.active)",
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            approved: "\(item.approved)",
            copayText: String(format: "%.2f", item.copay),
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictTaskEntryViews(_ items: [StrictTaskEntry]) -> [StrictTaskEntryView] {
        var views: [StrictTaskEntryView] = []
        for item in items {
            views.append(toStrictTaskEntryView(item))
        }
        return views
    }

    static func sumStrictTaskEntryView(_ view: StrictTaskEntryView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCopay + parsedCeiling
    }
}
