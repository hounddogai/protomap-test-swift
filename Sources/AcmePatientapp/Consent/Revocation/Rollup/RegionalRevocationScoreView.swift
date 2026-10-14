import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional revocation score.
    final class RegionalRevocationScoreView {
        var code: String
        var label: String
        var countryText: String
        var patientRef: String
        var amount: String
        var diagnosisCodeText: String
        var sequence: String
        var summary: String
        var name: String
        var phone: String
        var capacity: String
        var statusLabel: String

        init(code: String, label: String, countryText: String, patientRef: String, amount: String, diagnosisCodeText: String, sequence: String, summary: String, name: String, phone: String, capacity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.countryText = countryText
            self.patientRef = patientRef
            self.amount = amount
            self.diagnosisCodeText = diagnosisCodeText
            self.sequence = sequence
            self.summary = summary
            self.name = name
            self.phone = phone
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRevocationScoreView(_ item: RegionalRevocationScore) -> RegionalRevocationScoreView {
        return RegionalRevocationScoreView(
            code: item.code,
            label: item.label,
            countryText: item.country,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            amount: String(format: "%.2f", item.amount),
            diagnosisCodeText: item.diagnosisCode,
            sequence: String(item.sequence),
            summary: item.summary,
            name: Kit.Text.truncate(item.name, limit: 120),
            phone: item.phone,
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRevocationScoreViews(_ items: [RegionalRevocationScore]) -> [RegionalRevocationScoreView] {
        var views: [RegionalRevocationScoreView] = []
        for item in items {
            views.append(toRegionalRevocationScoreView(item))
        }
        return views
    }

    static func sumRegionalRevocationScoreView(_ view: RegionalRevocationScoreView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedAmount + Double(parsedSequence) + Double(parsedCapacity)
    }
}
