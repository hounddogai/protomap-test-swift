import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global care protocol rule.
    final class GlobalCareProtocolRuleView {
        var codeText: String
        var title: String
        var checksum: String
        var attemptsText: String
        var patientRef: String
        var createdAtText: String
        var categoryText: String
        var specialty: String
        var updatedAt: String
        var floorValue: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, title: String, checksum: String, attemptsText: String, patientRef: String, createdAtText: String, categoryText: String, specialty: String, updatedAt: String, floorValue: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.checksum = checksum
            self.attemptsText = attemptsText
            self.patientRef = patientRef
            self.createdAtText = createdAtText
            self.categoryText = categoryText
            self.specialty = specialty
            self.updatedAt = updatedAt
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCareProtocolRuleView(_ item: GlobalCareProtocolRule) -> GlobalCareProtocolRuleView {
        return GlobalCareProtocolRuleView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 40),
            checksum: item.checksum,
            attemptsText: String(item.attempts),
            patientRef: item.patientRef,
            createdAtText: String(item.createdAt),
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            specialty: item.specialty,
            updatedAt: String(item.updatedAt),
            floorValue: String(format: "%.2f", item.floorValue),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCareProtocolRuleViews(_ items: [GlobalCareProtocolRule]) -> [GlobalCareProtocolRuleView] {
        var views: [GlobalCareProtocolRuleView] = []
        for item in items {
            views.append(toGlobalCareProtocolRuleView(item))
        }
        return views
    }

    static func sumGlobalCareProtocolRuleView(_ view: GlobalCareProtocolRuleView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedAttempts) + Double(parsedCreatedAt) + Double(parsedUpdatedAt)
    }
}
