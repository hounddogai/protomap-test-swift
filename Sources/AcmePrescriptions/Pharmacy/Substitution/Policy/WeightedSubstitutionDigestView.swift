import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted substitution digest.
    final class WeightedSubstitutionDigestView {
        var code: String
        var label: String
        var budget: String
        var notesText: String
        var startsAt: String
        var bed: String
        var visitMinutesText: String
        var maximum: String
        var patientRef: String
        var statusLabel: String

        init(code: String, label: String, budget: String, notesText: String, startsAt: String, bed: String, visitMinutesText: String, maximum: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.budget = budget
            self.notesText = notesText
            self.startsAt = startsAt
            self.bed = bed
            self.visitMinutesText = visitMinutesText
            self.maximum = maximum
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedSubstitutionDigestView(_ item: WeightedSubstitutionDigest) -> WeightedSubstitutionDigestView {
        return WeightedSubstitutionDigestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            budget: String(format: "%.2f", item.budget),
            notesText: Kit.Text.truncate(item.notes, limit: 40),
            startsAt: String(item.startsAt),
            bed: item.bed,
            visitMinutesText: String(item.visitMinutes),
            maximum: String(format: "%.2f", item.maximum),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedSubstitutionDigestViews(_ items: [WeightedSubstitutionDigest]) -> [WeightedSubstitutionDigestView] {
        var views: [WeightedSubstitutionDigestView] = []
        for item in items {
            views.append(toWeightedSubstitutionDigestView(item))
        }
        return views
    }

    static func sumWeightedSubstitutionDigestView(_ view: WeightedSubstitutionDigestView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedBudget + Double(parsedStartsAt) + Double(parsedVisitMinutes)
    }
}
