import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol policy.
    final class CareProtocolPolicyView {
        var code: String
        var label: String
        var windowDays: String
        var maximum: String
        var patientRefText: String
        var externalRefText: String
        var notes: String
        var sequence: String
        var priority: String
        var minimum: String
        var statusLabel: String

        init(code: String, label: String, windowDays: String, maximum: String, patientRefText: String, externalRefText: String, notes: String, sequence: String, priority: String, minimum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.maximum = maximum
            self.patientRefText = patientRefText
            self.externalRefText = externalRefText
            self.notes = notes
            self.sequence = sequence
            self.priority = priority
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolPolicyView(_ item: CareProtocolPolicy) -> CareProtocolPolicyView {
        return CareProtocolPolicyView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            windowDays: String(item.windowDays),
            maximum: String(format: "%.2f", item.maximum),
            patientRefText: item.patientRef,
            externalRefText: item.externalRef,
            notes: item.notes,
            sequence: String(item.sequence),
            priority: String(item.priority),
            minimum: String(format: "%.2f", item.minimum),
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
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedWindowDays) + parsedMaximum + Double(parsedSequence)
    }
}
