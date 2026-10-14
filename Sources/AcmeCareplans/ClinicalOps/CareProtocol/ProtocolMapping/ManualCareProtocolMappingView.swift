import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a manual care protocol mapping.
    final class ManualCareProtocolMappingView {
        var code: String
        var name: String
        var endsAt: String
        var reviewer: String
        var unitText: String
        var cost: String
        var checksum: String
        var payer: String
        var sourceText: String
        var statusLabel: String

        init(code: String, name: String, endsAt: String, reviewer: String, unitText: String, cost: String, checksum: String, payer: String, sourceText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.unitText = unitText
            self.cost = cost
            self.checksum = checksum
            self.payer = payer
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toManualCareProtocolMappingView(_ item: ManualCareProtocolMapping) -> ManualCareProtocolMappingView {
        return ManualCareProtocolMappingView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            endsAt: String(item.endsAt),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            unitText: Kit.Text.truncate(item.unit, limit: 80),
            cost: String(format: "%.2f", item.cost),
            checksum: item.checksum,
            payer: item.payer,
            sourceText: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCareProtocolMappingViews(_ items: [ManualCareProtocolMapping]) -> [ManualCareProtocolMappingView] {
        var views: [ManualCareProtocolMappingView] = []
        for item in items {
            views.append(toManualCareProtocolMappingView(item))
        }
        return views
    }

    static func sumManualCareProtocolMappingView(_ view: ManualCareProtocolMappingView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedEndsAt) + parsedCost
    }
}
