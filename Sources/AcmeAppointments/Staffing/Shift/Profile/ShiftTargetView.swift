import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift target.
    final class ShiftTargetView {
        var codeText: String
        var nameText: String
        var category: String
        var segment: String
        var revision: String
        var ownerIDText: String
        var title: String
        var minimum: String
        var discountText: String
        var patientRef: String
        var country: String
        var statusLabel: String

        init(codeText: String, nameText: String, category: String, segment: String, revision: String, ownerIDText: String, title: String, minimum: String, discountText: String, patientRef: String, country: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.category = category
            self.segment = segment
            self.revision = revision
            self.ownerIDText = ownerIDText
            self.title = title
            self.minimum = minimum
            self.discountText = discountText
            self.patientRef = patientRef
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toShiftTargetView(_ item: ShiftTarget) -> ShiftTargetView {
        return ShiftTargetView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            category: item.category,
            segment: item.segment,
            revision: String(item.revision),
            ownerIDText: item.ownerID,
            title: item.title,
            minimum: String(format: "%.2f", item.minimum),
            discountText: String(format: "%.2f", item.discount),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftTargetViews(_ items: [ShiftTarget]) -> [ShiftTargetView] {
        var views: [ShiftTargetView] = []
        for item in items {
            views.append(toShiftTargetView(item))
        }
        return views
    }

    static func sumShiftTargetView(_ view: ShiftTargetView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedRevision) + parsedMinimum + parsedDiscount
    }
}
