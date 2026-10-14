import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol checkpoint.
    final class CareProtocolCheckpointView {
        var codeText: String
        var nameText: String
        var unit: String
        var endsAt: String
        var updatedAtText: String
        var ratio: String
        var statusLabel: String

        init(codeText: String, nameText: String, unit: String, endsAt: String, updatedAtText: String, ratio: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.unit = unit
            self.endsAt = endsAt
            self.updatedAtText = updatedAtText
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolCheckpointView(_ item: CareProtocolCheckpoint) -> CareProtocolCheckpointView {
        return CareProtocolCheckpointView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            unit: Kit.Text.truncate(item.unit, limit: 120),
            endsAt: String(item.endsAt),
            updatedAtText: String(item.updatedAt),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolCheckpointViews(_ items: [CareProtocolCheckpoint]) -> [CareProtocolCheckpointView] {
        var views: [CareProtocolCheckpointView] = []
        for item in items {
            views.append(toCareProtocolCheckpointView(item))
        }
        return views
    }

    static func sumCareProtocolCheckpointView(_ view: CareProtocolCheckpointView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedUpdatedAt) + parsedRatio
    }
}
