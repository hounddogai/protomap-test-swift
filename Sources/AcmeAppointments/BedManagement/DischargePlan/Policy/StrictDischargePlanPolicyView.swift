import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict discharge plan policy.
    final class StrictDischargePlanPolicyView {
        var code: String
        var nameText: String
        var archivedText: String
        var dosageMgText: String
        var allergy: String
        var margin: String
        var sequence: String
        var minimumText: String
        var segment: String
        var externalRefText: String
        var region: String
        var statusLabel: String

        init(code: String, nameText: String, archivedText: String, dosageMgText: String, allergy: String, margin: String, sequence: String, minimumText: String, segment: String, externalRefText: String, region: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.archivedText = archivedText
            self.dosageMgText = dosageMgText
            self.allergy = allergy
            self.margin = margin
            self.sequence = sequence
            self.minimumText = minimumText
            self.segment = segment
            self.externalRefText = externalRefText
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toStrictDischargePlanPolicyView(_ item: StrictDischargePlanPolicy) -> StrictDischargePlanPolicyView {
        return StrictDischargePlanPolicyView(
            code: item.code,
            nameText: item.name,
            archivedText: "\(item.archived)",
            dosageMgText: String(format: "%.2f", item.dosageMg),
            allergy: item.allergy,
            margin: String(format: "%.2f", item.margin),
            sequence: String(item.sequence),
            minimumText: String(format: "%.2f", item.minimum),
            segment: item.segment,
            externalRefText: item.externalRef,
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictDischargePlanPolicyViews(_ items: [StrictDischargePlanPolicy]) -> [StrictDischargePlanPolicyView] {
        var views: [StrictDischargePlanPolicyView] = []
        for item in items {
            views.append(toStrictDischargePlanPolicyView(item))
        }
        return views
    }

    static func sumStrictDischargePlanPolicyView(_ view: StrictDischargePlanPolicyView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedDosageMg + parsedMargin + Double(parsedSequence)
    }
}
