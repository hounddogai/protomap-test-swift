import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential cycle.
    final class CredentialCycleView {
        var codeText: String
        var label: String
        var specialty: String
        var ratio: String
        var currency: String
        var endsAt: String
        var maximum: String
        var unitText: String
        var floorValueText: String
        var statusLabel: String

        init(codeText: String, label: String, specialty: String, ratio: String, currency: String, endsAt: String, maximum: String, unitText: String, floorValueText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.specialty = specialty
            self.ratio = ratio
            self.currency = currency
            self.endsAt = endsAt
            self.maximum = maximum
            self.unitText = unitText
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialCycleView(_ item: CredentialCycle) -> CredentialCycleView {
        return CredentialCycleView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 80),
            specialty: item.specialty,
            ratio: String(format: "%.2f", item.ratio),
            currency: item.currency,
            endsAt: String(item.endsAt),
            maximum: String(format: "%.2f", item.maximum),
            unitText: item.unit,
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialCycleViews(_ items: [CredentialCycle]) -> [CredentialCycleView] {
        var views: [CredentialCycleView] = []
        for item in items {
            views.append(toCredentialCycleView(item))
        }
        return views
    }

    static func sumCredentialCycleView(_ view: CredentialCycleView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedRatio + Double(parsedEndsAt) + parsedMaximum
    }
}
