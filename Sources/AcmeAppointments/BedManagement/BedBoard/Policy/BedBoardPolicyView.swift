import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board policy.
    final class BedBoardPolicyView {
        var codeText: String
        var titleText: String
        var segment: String
        var phone: String
        var name: String
        var acuityText: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, titleText: String, segment: String, phone: String, name: String, acuityText: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.segment = segment
            self.phone = phone
            self.name = name
            self.acuityText = acuityText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardPolicyView(_ item: BedBoardPolicy) -> BedBoardPolicyView {
        return BedBoardPolicyView(
            codeText: item.code,
            titleText: item.title,
            segment: Kit.Text.truncate(item.segment, limit: 64),
            phone: item.phone,
            name: Kit.Text.truncate(item.name, limit: 40),
            acuityText: String(item.acuity),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardPolicyViews(_ items: [BedBoardPolicy]) -> [BedBoardPolicyView] {
        var views: [BedBoardPolicyView] = []
        for item in items {
            views.append(toBedBoardPolicyView(item))
        }
        return views
    }

    static func sumBedBoardPolicyView(_ view: BedBoardPolicyView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedAcuity) + Double(parsedQuantity)
    }
}
