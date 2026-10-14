import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation record.
    final class RevocationRecordView {
        var code: String
        var label: String
        var ceilingText: String
        var ratioText: String
        var windowDays: String
        var statusLabel: String

        init(code: String, label: String, ceilingText: String, ratioText: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceilingText = ceilingText
            self.ratioText = ratioText
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationRecordView(_ item: RevocationRecord) -> RevocationRecordView {
        return RevocationRecordView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            ceilingText: String(format: "%.2f", item.ceiling),
            ratioText: String(format: "%.2f", item.ratio),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationRecordViews(_ items: [RevocationRecord]) -> [RevocationRecordView] {
        var views: [RevocationRecordView] = []
        for item in items {
            views.append(toRevocationRecordView(item))
        }
        return views
    }

    static func sumRevocationRecordView(_ view: RevocationRecordView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedCeiling + parsedRatio + Double(parsedWindowDays)
    }
}
