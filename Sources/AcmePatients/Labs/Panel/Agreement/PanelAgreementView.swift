import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel agreement.
    final class PanelAgreementView {
        var code: String
        var titleText: String
        var phoneText: String
        var summaryText: String
        var capacity: String
        var ownerIDText: String
        var acuity: String
        var statusLabel: String

        init(code: String, titleText: String, phoneText: String, summaryText: String, capacity: String, ownerIDText: String, acuity: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.phoneText = phoneText
            self.summaryText = summaryText
            self.capacity = capacity
            self.ownerIDText = ownerIDText
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toPanelAgreementView(_ item: PanelAgreement) -> PanelAgreementView {
        return PanelAgreementView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            phoneText: item.phone,
            summaryText: item.summary,
            capacity: String(item.capacity),
            ownerIDText: item.ownerID,
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelAgreementViews(_ items: [PanelAgreement]) -> [PanelAgreementView] {
        var views: [PanelAgreementView] = []
        for item in items {
            views.append(toPanelAgreementView(item))
        }
        return views
    }

    static func sumPanelAgreementView(_ view: PanelAgreementView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedCapacity) + Double(parsedAcuity)
    }
}
