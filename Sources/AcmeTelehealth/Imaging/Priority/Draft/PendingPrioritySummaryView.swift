import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending priority summary.
    final class PendingPrioritySummaryView {
        var codeText: String
        var nameText: String
        var createdAtText: String
        var floorValue: String
        var summary: String
        var diagnosisCode: String
        var maximumText: String
        var statusLabel: String

        init(codeText: String, nameText: String, createdAtText: String, floorValue: String, summary: String, diagnosisCode: String, maximumText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.createdAtText = createdAtText
            self.floorValue = floorValue
            self.summary = summary
            self.diagnosisCode = diagnosisCode
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingPrioritySummaryView(_ item: PendingPrioritySummary) -> PendingPrioritySummaryView {
        return PendingPrioritySummaryView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            createdAtText: String(item.createdAt),
            floorValue: String(format: "%.2f", item.floorValue),
            summary: item.summary,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingPrioritySummaryViews(_ items: [PendingPrioritySummary]) -> [PendingPrioritySummaryView] {
        var views: [PendingPrioritySummaryView] = []
        for item in items {
            views.append(toPendingPrioritySummaryView(item))
        }
        return views
    }

    static func sumPendingPrioritySummaryView(_ view: PendingPrioritySummaryView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedCreatedAt) + parsedFloorValue + parsedMaximum
    }
}
