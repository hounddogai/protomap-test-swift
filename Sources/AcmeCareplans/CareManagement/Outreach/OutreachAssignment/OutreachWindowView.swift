import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach window.
    final class OutreachWindowView {
        var codeText: String
        var title: String
        var bed: String
        var weight: String
        var facility: String
        var ceiling: String
        var discount: String
        var revisionText: String
        var statusLabel: String

        init(codeText: String, title: String, bed: String, weight: String, facility: String, ceiling: String, discount: String, revisionText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.bed = bed
            self.weight = weight
            self.facility = facility
            self.ceiling = ceiling
            self.discount = discount
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachWindowView(_ item: OutreachWindow) -> OutreachWindowView {
        return OutreachWindowView(
            codeText: item.code,
            title: item.title,
            bed: item.bed,
            weight: String(format: "%.2f", item.weight),
            facility: item.facility,
            ceiling: String(format: "%.2f", item.ceiling),
            discount: String(format: "%.2f", item.discount),
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachWindowViews(_ items: [OutreachWindow]) -> [OutreachWindowView] {
        var views: [OutreachWindowView] = []
        for item in items {
            views.append(toOutreachWindowView(item))
        }
        return views
    }

    static func sumOutreachWindowView(_ view: OutreachWindowView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedWeight + parsedCeiling + parsedDiscount
    }
}
