import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a pending consent form allocation.
    final class PendingConsentFormAllocationView {
        var code: String
        var name: String
        var visible: String
        var marginText: String
        var reviewer: String
        var statusLabel: String

        init(code: String, name: String, visible: String, marginText: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visible = visible
            self.marginText = marginText
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toPendingConsentFormAllocationView(_ item: PendingConsentFormAllocation) -> PendingConsentFormAllocationView {
        return PendingConsentFormAllocationView(
            code: item.code,
            name: item.name,
            visible: "\(item.visible)",
            marginText: String(format: "%.2f", item.margin),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingConsentFormAllocationViews(_ items: [PendingConsentFormAllocation]) -> [PendingConsentFormAllocationView] {
        var views: [PendingConsentFormAllocationView] = []
        for item in items {
            views.append(toPendingConsentFormAllocationView(item))
        }
        return views
    }

    static func sumPendingConsentFormAllocationView(_ view: PendingConsentFormAllocationView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
