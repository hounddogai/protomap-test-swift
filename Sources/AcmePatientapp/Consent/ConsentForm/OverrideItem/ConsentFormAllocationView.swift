import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form allocation.
    final class ConsentFormAllocationView {
        var codeText: String
        var titleText: String
        var attempts: String
        var floorValue: String
        var sequenceText: String
        var limit: String
        var facilityText: String
        var budget: String
        var locale: String
        var pinned: String
        var retries: String
        var statusLabel: String

        init(codeText: String, titleText: String, attempts: String, floorValue: String, sequenceText: String, limit: String, facilityText: String, budget: String, locale: String, pinned: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.attempts = attempts
            self.floorValue = floorValue
            self.sequenceText = sequenceText
            self.limit = limit
            self.facilityText = facilityText
            self.budget = budget
            self.locale = locale
            self.pinned = pinned
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormAllocationView(_ item: ConsentFormAllocation) -> ConsentFormAllocationView {
        return ConsentFormAllocationView(
            codeText: item.code,
            titleText: item.title,
            attempts: String(item.attempts),
            floorValue: String(format: "%.2f", item.floorValue),
            sequenceText: String(item.sequence),
            limit: String(item.limit),
            facilityText: Kit.Text.truncate(item.facility, limit: 120),
            budget: String(format: "%.2f", item.budget),
            locale: Kit.Text.truncate(item.locale, limit: 64),
            pinned: "\(item.pinned)",
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormAllocationViews(_ items: [ConsentFormAllocation]) -> [ConsentFormAllocationView] {
        var views: [ConsentFormAllocationView] = []
        for item in items {
            views.append(toConsentFormAllocationView(item))
        }
        return views
    }

    static func sumConsentFormAllocationView(_ view: ConsentFormAllocationView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedAttempts) + parsedFloorValue + Double(parsedSequence)
    }
}
