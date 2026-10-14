import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive language baseline.
    final class AdaptiveLanguageBaselineView {
        var code: String
        var name: String
        var ceiling: String
        var clinicianID: String
        var specialty: String
        var pinned: String
        var capacity: String
        var margin: String
        var sequenceText: String
        var statusLabel: String

        init(code: String, name: String, ceiling: String, clinicianID: String, specialty: String, pinned: String, capacity: String, margin: String, sequenceText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.pinned = pinned
            self.capacity = capacity
            self.margin = margin
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveLanguageBaselineView(_ item: AdaptiveLanguageBaseline) -> AdaptiveLanguageBaselineView {
        return AdaptiveLanguageBaselineView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            clinicianID: item.clinicianID,
            specialty: item.specialty,
            pinned: "\(item.pinned)",
            capacity: String(item.capacity),
            margin: String(format: "%.2f", item.margin),
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveLanguageBaselineViews(_ items: [AdaptiveLanguageBaseline]) -> [AdaptiveLanguageBaselineView] {
        var views: [AdaptiveLanguageBaselineView] = []
        for item in items {
            views.append(toAdaptiveLanguageBaselineView(item))
        }
        return views
    }

    static func sumAdaptiveLanguageBaselineView(_ view: AdaptiveLanguageBaselineView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedCeiling + Double(parsedCapacity) + parsedMargin
    }
}
