import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a legacy statement threshold.
    final class LegacyStatementThresholdView {
        var codeText: String
        var labelText: String
        var ceiling: String
        var createdAt: String
        var clinicianID: String
        var descriptionText: String
        var procedureCode: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, labelText: String, ceiling: String, createdAt: String, clinicianID: String, descriptionText: String, procedureCode: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.ceiling = ceiling
            self.createdAt = createdAt
            self.clinicianID = clinicianID
            self.descriptionText = descriptionText
            self.procedureCode = procedureCode
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyStatementThresholdView(_ item: LegacyStatementThreshold) -> LegacyStatementThresholdView {
        return LegacyStatementThresholdView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            ceiling: String(format: "%.2f", item.ceiling),
            createdAt: String(item.createdAt),
            clinicianID: item.clinicianID,
            descriptionText: item.description,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyStatementThresholdViews(_ items: [LegacyStatementThreshold]) -> [LegacyStatementThresholdView] {
        var views: [LegacyStatementThresholdView] = []
        for item in items {
            views.append(toLegacyStatementThresholdView(item))
        }
        return views
    }

    static func sumLegacyStatementThresholdView(_ view: LegacyStatementThresholdView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedCeiling + Double(parsedCreatedAt) + Double(parsedExpiresAt)
    }
}
