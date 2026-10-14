import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a legacy worklist quota.
    final class LegacyWorklistQuotaView {
        var code: String
        var name: String
        var category: String
        var ceiling: String
        var checksum: String
        var dosageMgText: String
        var version: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, name: String, category: String, ceiling: String, checksum: String, dosageMgText: String, version: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.category = category
            self.ceiling = ceiling
            self.checksum = checksum
            self.dosageMgText = dosageMgText
            self.version = version
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyWorklistQuotaView(_ item: LegacyWorklistQuota) -> LegacyWorklistQuotaView {
        return LegacyWorklistQuotaView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 120),
            category: item.category,
            ceiling: String(format: "%.2f", item.ceiling),
            checksum: item.checksum,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            version: String(item.version),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyWorklistQuotaViews(_ items: [LegacyWorklistQuota]) -> [LegacyWorklistQuotaView] {
        var views: [LegacyWorklistQuotaView] = []
        for item in items {
            views.append(toLegacyWorklistQuotaView(item))
        }
        return views
    }

    static func sumLegacyWorklistQuotaView(_ view: LegacyWorklistQuotaView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedCeiling + parsedDosageMg + Double(parsedVersion)
    }
}
