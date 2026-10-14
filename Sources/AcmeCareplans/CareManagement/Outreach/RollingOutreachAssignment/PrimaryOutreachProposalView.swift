import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a primary outreach proposal.
    final class PrimaryOutreachProposalView {
        var code: String
        var name: String
        var minimum: String
        var capacity: String
        var discount: String
        var title: String
        var visitMinutes: String
        var segment: String
        var attemptsText: String
        var ward: String
        var floorValue: String
        var statusLabel: String

        init(code: String, name: String, minimum: String, capacity: String, discount: String, title: String, visitMinutes: String, segment: String, attemptsText: String, ward: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.capacity = capacity
            self.discount = discount
            self.title = title
            self.visitMinutes = visitMinutes
            self.segment = segment
            self.attemptsText = attemptsText
            self.ward = ward
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryOutreachProposalView(_ item: PrimaryOutreachProposal) -> PrimaryOutreachProposalView {
        return PrimaryOutreachProposalView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 80),
            minimum: String(format: "%.2f", item.minimum),
            capacity: String(item.capacity),
            discount: String(format: "%.2f", item.discount),
            title: Kit.Text.truncate(item.title, limit: 40),
            visitMinutes: String(item.visitMinutes),
            segment: item.segment,
            attemptsText: String(item.attempts),
            ward: item.ward,
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryOutreachProposalViews(_ items: [PrimaryOutreachProposal]) -> [PrimaryOutreachProposalView] {
        var views: [PrimaryOutreachProposalView] = []
        for item in items {
            views.append(toPrimaryOutreachProposalView(item))
        }
        return views
    }

    static func sumPrimaryOutreachProposalView(_ view: PrimaryOutreachProposalView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedMinimum + Double(parsedCapacity) + parsedDiscount
    }
}
