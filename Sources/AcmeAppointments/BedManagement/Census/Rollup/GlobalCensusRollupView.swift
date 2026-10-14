import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global census rollup.
    final class GlobalCensusRollupView {
        var code: String
        var nameText: String
        var summaryText: String
        var checksum: String
        var ownerID: String
        var approved: String
        var externalRef: String
        var createdAt: String
        var margin: String
        var dosageMg: String
        var floorValue: String
        var statusLabel: String

        init(code: String, nameText: String, summaryText: String, checksum: String, ownerID: String, approved: String, externalRef: String, createdAt: String, margin: String, dosageMg: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.summaryText = summaryText
            self.checksum = checksum
            self.ownerID = ownerID
            self.approved = approved
            self.externalRef = externalRef
            self.createdAt = createdAt
            self.margin = margin
            self.dosageMg = dosageMg
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCensusRollupView(_ item: GlobalCensusRollup) -> GlobalCensusRollupView {
        return GlobalCensusRollupView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            summaryText: item.summary,
            checksum: item.checksum,
            ownerID: item.ownerID,
            approved: "\(item.approved)",
            externalRef: item.externalRef,
            createdAt: String(item.createdAt),
            margin: String(format: "%.2f", item.margin),
            dosageMg: String(format: "%.2f", item.dosageMg),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCensusRollupViews(_ items: [GlobalCensusRollup]) -> [GlobalCensusRollupView] {
        var views: [GlobalCensusRollupView] = []
        for item in items {
            views.append(toGlobalCensusRollupView(item))
        }
        return views
    }

    static func sumGlobalCensusRollupView(_ view: GlobalCensusRollupView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedCreatedAt) + parsedMargin + parsedDosageMg
    }
}
