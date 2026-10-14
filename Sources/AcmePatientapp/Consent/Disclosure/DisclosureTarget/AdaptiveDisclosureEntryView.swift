import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive disclosure entry.
    final class AdaptiveDisclosureEntryView {
        var codeText: String
        var name: String
        var durationMinutes: String
        var windowDays: String
        var discountText: String
        var allergy: String
        var batchSize: String
        var segmentText: String
        var statusLabel: String

        init(codeText: String, name: String, durationMinutes: String, windowDays: String, discountText: String, allergy: String, batchSize: String, segmentText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.durationMinutes = durationMinutes
            self.windowDays = windowDays
            self.discountText = discountText
            self.allergy = allergy
            self.batchSize = batchSize
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveDisclosureEntryView(_ item: AdaptiveDisclosureEntry) -> AdaptiveDisclosureEntryView {
        return AdaptiveDisclosureEntryView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 80),
            durationMinutes: String(item.durationMinutes),
            windowDays: String(item.windowDays),
            discountText: String(format: "%.2f", item.discount),
            allergy: item.allergy,
            batchSize: String(item.batchSize),
            segmentText: Kit.Text.truncate(item.segment, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveDisclosureEntryViews(_ items: [AdaptiveDisclosureEntry]) -> [AdaptiveDisclosureEntryView] {
        var views: [AdaptiveDisclosureEntryView] = []
        for item in items {
            views.append(toAdaptiveDisclosureEntryView(item))
        }
        return views
    }

    static func sumAdaptiveDisclosureEntryView(_ view: AdaptiveDisclosureEntryView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedWindowDays) + parsedDiscount
    }
}
