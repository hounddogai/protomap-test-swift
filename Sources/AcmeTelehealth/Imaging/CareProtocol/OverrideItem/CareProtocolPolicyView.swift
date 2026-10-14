import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol policy.
    final class CareProtocolPolicyView {
        var code: String
        var name: String
        var locale: String
        var encounterIDText: String
        var version: String
        var ownerIDText: String
        var description: String
        var updatedAtText: String
        var title: String
        var refills: String
        var quantity: String
        var statusLabel: String

        init(code: String, name: String, locale: String, encounterIDText: String, version: String, ownerIDText: String, description: String, updatedAtText: String, title: String, refills: String, quantity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.locale = locale
            self.encounterIDText = encounterIDText
            self.version = version
            self.ownerIDText = ownerIDText
            self.description = description
            self.updatedAtText = updatedAtText
            self.title = title
            self.refills = refills
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolPolicyView(_ item: CareProtocolPolicy) -> CareProtocolPolicyView {
        return CareProtocolPolicyView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            locale: item.locale,
            encounterIDText: item.encounterID,
            version: String(item.version),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 120),
            description: item.description,
            updatedAtText: String(item.updatedAt),
            title: item.title,
            refills: String(item.refills),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolPolicyViews(_ items: [CareProtocolPolicy]) -> [CareProtocolPolicyView] {
        var views: [CareProtocolPolicyView] = []
        for item in items {
            views.append(toCareProtocolPolicyView(item))
        }
        return views
    }

    static func sumCareProtocolPolicyView(_ view: CareProtocolPolicyView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedVersion) + Double(parsedUpdatedAt) + Double(parsedRefills)
    }
}
