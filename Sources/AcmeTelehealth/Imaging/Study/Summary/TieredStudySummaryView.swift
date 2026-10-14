import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered study summary.
    final class TieredStudySummaryView {
        var codeText: String
        var nameText: String
        var patientRef: String
        var region: String
        var createdAtText: String
        var pinned: String
        var priority: String
        var statusLabel: String

        init(codeText: String, nameText: String, patientRef: String, region: String, createdAtText: String, pinned: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.patientRef = patientRef
            self.region = region
            self.createdAtText = createdAtText
            self.pinned = pinned
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toTieredStudySummaryView(_ item: TieredStudySummary) -> TieredStudySummaryView {
        return TieredStudySummaryView(
            codeText: item.code,
            nameText: item.name,
            patientRef: item.patientRef,
            region: Kit.Text.truncate(item.region, limit: 80),
            createdAtText: String(item.createdAt),
            pinned: "\(item.pinned)",
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredStudySummaryViews(_ items: [TieredStudySummary]) -> [TieredStudySummaryView] {
        var views: [TieredStudySummaryView] = []
        for item in items {
            views.append(toTieredStudySummaryView(item))
        }
        return views
    }

    static func sumTieredStudySummaryView(_ view: TieredStudySummaryView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedPriority)
    }
}
