import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a manual specimen agreement.
    final class ManualSpecimenAgreementView {
        var codeText: String
        var title: String
        var ownerID: String
        var cost: String
        var retries: String
        var createdAt: String
        var dosageMg: String
        var graceDaysText: String
        var contactEmailText: String
        var statusLabel: String

        init(codeText: String, title: String, ownerID: String, cost: String, retries: String, createdAt: String, dosageMg: String, graceDaysText: String, contactEmailText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ownerID = ownerID
            self.cost = cost
            self.retries = retries
            self.createdAt = createdAt
            self.dosageMg = dosageMg
            self.graceDaysText = graceDaysText
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toManualSpecimenAgreementView(_ item: ManualSpecimenAgreement) -> ManualSpecimenAgreementView {
        return ManualSpecimenAgreementView(
            codeText: item.code,
            title: item.title,
            ownerID: item.ownerID,
            cost: String(format: "%.2f", item.cost),
            retries: String(item.retries),
            createdAt: String(item.createdAt),
            dosageMg: String(format: "%.2f", item.dosageMg),
            graceDaysText: String(item.graceDays),
            contactEmailText: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualSpecimenAgreementViews(_ items: [ManualSpecimenAgreement]) -> [ManualSpecimenAgreementView] {
        var views: [ManualSpecimenAgreementView] = []
        for item in items {
            views.append(toManualSpecimenAgreementView(item))
        }
        return views
    }

    static func sumManualSpecimenAgreementView(_ view: ManualSpecimenAgreementView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedCost + Double(parsedRetries) + Double(parsedCreatedAt)
    }
}
