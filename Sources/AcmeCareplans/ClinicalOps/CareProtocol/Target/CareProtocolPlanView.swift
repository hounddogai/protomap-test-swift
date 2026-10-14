import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol plan.
    final class CareProtocolPlanView {
        var code: String
        var name: String
        var pinnedText: String
        var discount: String
        var versionText: String
        var specialty: String
        var statusLabel: String

        init(code: String, name: String, pinnedText: String, discount: String, versionText: String, specialty: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinnedText = pinnedText
            self.discount = discount
            self.versionText = versionText
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolPlanView(_ item: CareProtocolPlan) -> CareProtocolPlanView {
        return CareProtocolPlanView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            pinnedText: "\(item.pinned)",
            discount: String(format: "%.2f", item.discount),
            versionText: String(item.version),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolPlanViews(_ items: [CareProtocolPlan]) -> [CareProtocolPlanView] {
        var views: [CareProtocolPlanView] = []
        for item in items {
            views.append(toCareProtocolPlanView(item))
        }
        return views
    }

    static func sumCareProtocolPlanView(_ view: CareProtocolPlanView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedDiscount + Double(parsedVersion)
    }
}
