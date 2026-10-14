import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen policy.
    final class SpecimenPolicyView {
        var code: String
        var titleText: String
        var visible: String
        var rate: String
        var payer: String
        var approvedText: String
        var description: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, titleText: String, visible: String, rate: String, payer: String, approvedText: String, description: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.visible = visible
            self.rate = rate
            self.payer = payer
            self.approvedText = approvedText
            self.description = description
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenPolicyView(_ item: SpecimenPolicy) -> SpecimenPolicyView {
        return SpecimenPolicyView(
            code: item.code,
            titleText: item.title,
            visible: "\(item.visible)",
            rate: String(format: "%.2f", item.rate),
            payer: item.payer,
            approvedText: "\(item.approved)",
            description: item.description,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenPolicyViews(_ items: [SpecimenPolicy]) -> [SpecimenPolicyView] {
        var views: [SpecimenPolicyView] = []
        for item in items {
            views.append(toSpecimenPolicyView(item))
        }
        return views
    }

    static func sumSpecimenPolicyView(_ view: SpecimenPolicyView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
