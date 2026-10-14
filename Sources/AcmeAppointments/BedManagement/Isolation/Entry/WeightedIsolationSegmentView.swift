import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a weighted isolation segment.
    final class WeightedIsolationSegmentView {
        var codeText: String
        var name: String
        var approved: String
        var durationMinutesText: String
        var copay: String
        var sequenceText: String
        var specialtyText: String
        var currencyText: String
        var patientRef: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, name: String, approved: String, durationMinutesText: String, copay: String, sequenceText: String, specialtyText: String, currencyText: String, patientRef: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.approved = approved
            self.durationMinutesText = durationMinutesText
            self.copay = copay
            self.sequenceText = sequenceText
            self.specialtyText = specialtyText
            self.currencyText = currencyText
            self.patientRef = patientRef
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedIsolationSegmentView(_ item: WeightedIsolationSegment) -> WeightedIsolationSegmentView {
        return WeightedIsolationSegmentView(
            codeText: item.code,
            name: item.name,
            approved: "\(item.approved)",
            durationMinutesText: String(item.durationMinutes),
            copay: String(format: "%.2f", item.copay),
            sequenceText: String(item.sequence),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 80),
            currencyText: Kit.Text.truncate(item.currency, limit: 40),
            patientRef: item.patientRef,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedIsolationSegmentViews(_ items: [WeightedIsolationSegment]) -> [WeightedIsolationSegmentView] {
        var views: [WeightedIsolationSegmentView] = []
        for item in items {
            views.append(toWeightedIsolationSegmentView(item))
        }
        return views
    }

    static func sumWeightedIsolationSegmentView(_ view: WeightedIsolationSegmentView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedDurationMinutes) + parsedCopay + Double(parsedSequence)
    }
}
