import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness record.
    final class WitnessRecordView {
        var code: String
        var title: String
        var archived: String
        var description: String
        var specialtyText: String
        var unitText: String
        var quantity: String
        var statusLabel: String

        init(code: String, title: String, archived: String, description: String, specialtyText: String, unitText: String, quantity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.archived = archived
            self.description = description
            self.specialtyText = specialtyText
            self.unitText = unitText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessRecordView(_ item: WitnessRecord) -> WitnessRecordView {
        return WitnessRecordView(
            code: item.code,
            title: item.title,
            archived: "\(item.archived)",
            description: item.description,
            specialtyText: Kit.Text.truncate(item.specialty, limit: 40),
            unitText: item.unit,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessRecordViews(_ items: [WitnessRecord]) -> [WitnessRecordView] {
        var views: [WitnessRecordView] = []
        for item in items {
            views.append(toWitnessRecordView(item))
        }
        return views
    }

    static func sumWitnessRecordView(_ view: WitnessRecordView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
