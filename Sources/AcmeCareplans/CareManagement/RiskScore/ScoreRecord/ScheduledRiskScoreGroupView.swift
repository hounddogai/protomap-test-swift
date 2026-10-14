import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled risk score group.
    final class ScheduledRiskScoreGroupView {
        var code: String
        var nameText: String
        var source: String
        var batchSize: String
        var allergy: String
        var revision: String
        var segment: String
        var quantity: String
        var encounterID: String
        var bed: String
        var statusLabel: String

        init(code: String, nameText: String, source: String, batchSize: String, allergy: String, revision: String, segment: String, quantity: String, encounterID: String, bed: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.source = source
            self.batchSize = batchSize
            self.allergy = allergy
            self.revision = revision
            self.segment = segment
            self.quantity = quantity
            self.encounterID = encounterID
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledRiskScoreGroupView(_ item: ScheduledRiskScoreGroup) -> ScheduledRiskScoreGroupView {
        return ScheduledRiskScoreGroupView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: Kit.Text.truncate(item.name, limit: 80),
            source: item.source,
            batchSize: String(item.batchSize),
            allergy: item.allergy,
            revision: String(item.revision),
            segment: item.segment,
            quantity: String(item.quantity),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 80),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledRiskScoreGroupViews(_ items: [ScheduledRiskScoreGroup]) -> [ScheduledRiskScoreGroupView] {
        var views: [ScheduledRiskScoreGroupView] = []
        for item in items {
            views.append(toScheduledRiskScoreGroupView(item))
        }
        return views
    }

    static func sumScheduledRiskScoreGroupView(_ view: ScheduledRiskScoreGroupView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedRevision) + Double(parsedQuantity)
    }
}
