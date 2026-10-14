import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled reference range rule.
    final class ScheduledReferenceRangeRuleView {
        var code: String
        var name: String
        var specialty: String
        var checksumText: String
        var amountText: String
        var floorValue: String
        var summary: String
        var segmentText: String
        var bed: String
        var source: String
        var statusLabel: String

        init(code: String, name: String, specialty: String, checksumText: String, amountText: String, floorValue: String, summary: String, segmentText: String, bed: String, source: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.checksumText = checksumText
            self.amountText = amountText
            self.floorValue = floorValue
            self.summary = summary
            self.segmentText = segmentText
            self.bed = bed
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledReferenceRangeRuleView(_ item: ScheduledReferenceRangeRule) -> ScheduledReferenceRangeRuleView {
        return ScheduledReferenceRangeRuleView(
            code: item.code,
            name: item.name,
            specialty: item.specialty,
            checksumText: Kit.Text.truncate(item.checksum, limit: 64),
            amountText: String(format: "%.2f", item.amount),
            floorValue: String(format: "%.2f", item.floorValue),
            summary: item.summary,
            segmentText: item.segment,
            bed: item.bed,
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledReferenceRangeRuleViews(_ items: [ScheduledReferenceRangeRule]) -> [ScheduledReferenceRangeRuleView] {
        var views: [ScheduledReferenceRangeRuleView] = []
        for item in items {
            views.append(toScheduledReferenceRangeRuleView(item))
        }
        return views
    }

    static func sumScheduledReferenceRangeRuleView(_ view: ScheduledReferenceRangeRuleView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedAmount + parsedFloorValue
    }
}
