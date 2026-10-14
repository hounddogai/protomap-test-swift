import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a tiered specimen assignment.
    final class TieredSpecimenAssignmentView {
        var codeText: String
        var name: String
        var startsAt: String
        var discount: String
        var marginText: String
        var sequence: String
        var phone: String
        var facility: String
        var minimum: String
        var statusLabel: String

        init(codeText: String, name: String, startsAt: String, discount: String, marginText: String, sequence: String, phone: String, facility: String, minimum: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.startsAt = startsAt
            self.discount = discount
            self.marginText = marginText
            self.sequence = sequence
            self.phone = phone
            self.facility = facility
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toTieredSpecimenAssignmentView(_ item: TieredSpecimenAssignment) -> TieredSpecimenAssignmentView {
        return TieredSpecimenAssignmentView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            startsAt: String(item.startsAt),
            discount: String(format: "%.2f", item.discount),
            marginText: String(format: "%.2f", item.margin),
            sequence: String(item.sequence),
            phone: Kit.Text.truncate(item.phone, limit: 80),
            facility: Kit.Text.truncate(item.facility, limit: 40),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredSpecimenAssignmentViews(_ items: [TieredSpecimenAssignment]) -> [TieredSpecimenAssignmentView] {
        var views: [TieredSpecimenAssignmentView] = []
        for item in items {
            views.append(toTieredSpecimenAssignmentView(item))
        }
        return views
    }

    static func sumTieredSpecimenAssignmentView(_ view: TieredSpecimenAssignmentView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedStartsAt) + parsedDiscount + parsedMargin
    }
}
