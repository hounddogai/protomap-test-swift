import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual recall group.
    final class ManualRecallGroupView {
        var code: String
        var name: String
        var label: String
        var maximumText: String
        var segment: String
        var startsAt: String
        var acuity: String
        var attemptsText: String
        var weight: String
        var procedureCodeText: String
        var bedText: String
        var statusLabel: String

        init(code: String, name: String, label: String, maximumText: String, segment: String, startsAt: String, acuity: String, attemptsText: String, weight: String, procedureCodeText: String, bedText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.label = label
            self.maximumText = maximumText
            self.segment = segment
            self.startsAt = startsAt
            self.acuity = acuity
            self.attemptsText = attemptsText
            self.weight = weight
            self.procedureCodeText = procedureCodeText
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toManualRecallGroupView(_ item: ManualRecallGroup) -> ManualRecallGroupView {
        return ManualRecallGroupView(
            code: item.code,
            name: item.name,
            label: item.label,
            maximumText: String(format: "%.2f", item.maximum),
            segment: item.segment,
            startsAt: String(item.startsAt),
            acuity: String(item.acuity),
            attemptsText: String(item.attempts),
            weight: String(format: "%.2f", item.weight),
            procedureCodeText: item.procedureCode,
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRecallGroupViews(_ items: [ManualRecallGroup]) -> [ManualRecallGroupView] {
        var views: [ManualRecallGroupView] = []
        for item in items {
            views.append(toManualRecallGroupView(item))
        }
        return views
    }

    static func sumManualRecallGroupView(_ view: ManualRecallGroupView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedMaximum + Double(parsedStartsAt) + Double(parsedAcuity)
    }
}
