import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study claim.
    final class StudyClaimView {
        var code: String
        var label: String
        var quantity: String
        var acuity: String
        var floorValue: String
        var category: String
        var batchSize: String
        var payer: String
        var statusLabel: String

        init(code: String, label: String, quantity: String, acuity: String, floorValue: String, category: String, batchSize: String, payer: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.acuity = acuity
            self.floorValue = floorValue
            self.category = category
            self.batchSize = batchSize
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toStudyClaimView(_ item: StudyClaim) -> StudyClaimView {
        return StudyClaimView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            quantity: String(item.quantity),
            acuity: String(item.acuity),
            floorValue: String(format: "%.2f", item.floorValue),
            category: Kit.Text.truncate(item.category, limit: 64),
            batchSize: String(item.batchSize),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyClaimViews(_ items: [StudyClaim]) -> [StudyClaimView] {
        var views: [StudyClaimView] = []
        for item in items {
            views.append(toStudyClaimView(item))
        }
        return views
    }

    static func sumStudyClaimView(_ view: StudyClaimView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedQuantity) + Double(parsedAcuity) + parsedFloorValue
    }
}
