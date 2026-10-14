import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary order set digest.
    final class PrimaryOrderSetDigestView {
        var code: String
        var titleText: String
        var contactEmail: String
        var budget: String
        var capacity: String
        var maximum: String
        var acuity: String
        var name: String
        var expiresAt: String
        var archived: String
        var statusLabel: String

        init(code: String, titleText: String, contactEmail: String, budget: String, capacity: String, maximum: String, acuity: String, name: String, expiresAt: String, archived: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.contactEmail = contactEmail
            self.budget = budget
            self.capacity = capacity
            self.maximum = maximum
            self.acuity = acuity
            self.name = name
            self.expiresAt = expiresAt
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryOrderSetDigestView(_ item: PrimaryOrderSetDigest) -> PrimaryOrderSetDigestView {
        return PrimaryOrderSetDigestView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            contactEmail: item.contactEmail,
            budget: String(format: "%.2f", item.budget),
            capacity: String(item.capacity),
            maximum: String(format: "%.2f", item.maximum),
            acuity: String(item.acuity),
            name: item.name,
            expiresAt: String(item.expiresAt),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryOrderSetDigestViews(_ items: [PrimaryOrderSetDigest]) -> [PrimaryOrderSetDigestView] {
        var views: [PrimaryOrderSetDigestView] = []
        for item in items {
            views.append(toPrimaryOrderSetDigestView(item))
        }
        return views
    }

    static func sumPrimaryOrderSetDigestView(_ view: PrimaryOrderSetDigestView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedBudget + Double(parsedCapacity) + parsedMaximum
    }
}
