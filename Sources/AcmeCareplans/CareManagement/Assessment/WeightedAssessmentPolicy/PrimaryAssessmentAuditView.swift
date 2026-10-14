import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a primary assessment audit.
    final class PrimaryAssessmentAuditView {
        var codeText: String
        var name: String
        var retries: String
        var facility: String
        var priority: String
        var payer: String
        var summary: String
        var maximum: String
        var country: String
        var statusLabel: String

        init(codeText: String, name: String, retries: String, facility: String, priority: String, payer: String, summary: String, maximum: String, country: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.retries = retries
            self.facility = facility
            self.priority = priority
            self.payer = payer
            self.summary = summary
            self.maximum = maximum
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryAssessmentAuditView(_ item: PrimaryAssessmentAudit) -> PrimaryAssessmentAuditView {
        return PrimaryAssessmentAuditView(
            codeText: item.code,
            name: item.name,
            retries: String(item.retries),
            facility: item.facility,
            priority: String(item.priority),
            payer: item.payer,
            summary: Kit.Text.truncate(item.summary, limit: 120),
            maximum: String(format: "%.2f", item.maximum),
            country: Kit.Text.truncate(item.country, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryAssessmentAuditViews(_ items: [PrimaryAssessmentAudit]) -> [PrimaryAssessmentAuditView] {
        var views: [PrimaryAssessmentAuditView] = []
        for item in items {
            views.append(toPrimaryAssessmentAuditView(item))
        }
        return views
    }

    static func sumPrimaryAssessmentAuditView(_ view: PrimaryAssessmentAuditView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedRetries) + Double(parsedPriority) + parsedMaximum
    }
}
