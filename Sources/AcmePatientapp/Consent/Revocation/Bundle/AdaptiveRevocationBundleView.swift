import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive revocation bundle.
    final class AdaptiveRevocationBundleView {
        var codeText: String
        var titleText: String
        var pinned: String
        var allergy: String
        var threshold: String
        var contactEmail: String
        var attempts: String
        var capacity: String
        var ward: String
        var statusLabel: String

        init(codeText: String, titleText: String, pinned: String, allergy: String, threshold: String, contactEmail: String, attempts: String, capacity: String, ward: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.pinned = pinned
            self.allergy = allergy
            self.threshold = threshold
            self.contactEmail = contactEmail
            self.attempts = attempts
            self.capacity = capacity
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveRevocationBundleView(_ item: AdaptiveRevocationBundle) -> AdaptiveRevocationBundleView {
        return AdaptiveRevocationBundleView(
            codeText: item.code,
            titleText: item.title,
            pinned: "\(item.pinned)",
            allergy: Kit.Text.truncate(item.allergy, limit: 40),
            threshold: String(format: "%.2f", item.threshold),
            contactEmail: item.contactEmail,
            attempts: String(item.attempts),
            capacity: String(item.capacity),
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveRevocationBundleViews(_ items: [AdaptiveRevocationBundle]) -> [AdaptiveRevocationBundleView] {
        var views: [AdaptiveRevocationBundleView] = []
        for item in items {
            views.append(toAdaptiveRevocationBundleView(item))
        }
        return views
    }

    static func sumAdaptiveRevocationBundleView(_ view: AdaptiveRevocationBundleView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedThreshold + Double(parsedAttempts) + Double(parsedCapacity)
    }
}
