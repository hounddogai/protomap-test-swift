import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive credential mapping.
    final class AdaptiveCredentialMappingView {
        var codeText: String
        var label: String
        var country: String
        var endsAt: String
        var payer: String
        var approved: String
        var limit: String
        var capacity: String
        var visibleText: String
        var facility: String
        var statusLabel: String

        init(codeText: String, label: String, country: String, endsAt: String, payer: String, approved: String, limit: String, capacity: String, visibleText: String, facility: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.country = country
            self.endsAt = endsAt
            self.payer = payer
            self.approved = approved
            self.limit = limit
            self.capacity = capacity
            self.visibleText = visibleText
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCredentialMappingView(_ item: AdaptiveCredentialMapping) -> AdaptiveCredentialMappingView {
        return AdaptiveCredentialMappingView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            country: item.country,
            endsAt: String(item.endsAt),
            payer: item.payer,
            approved: "\(item.approved)",
            limit: String(item.limit),
            capacity: String(item.capacity),
            visibleText: "\(item.visible)",
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCredentialMappingViews(_ items: [AdaptiveCredentialMapping]) -> [AdaptiveCredentialMappingView] {
        var views: [AdaptiveCredentialMappingView] = []
        for item in items {
            views.append(toAdaptiveCredentialMappingView(item))
        }
        return views
    }

    static func sumAdaptiveCredentialMappingView(_ view: AdaptiveCredentialMappingView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedLimit) + Double(parsedCapacity)
    }
}
