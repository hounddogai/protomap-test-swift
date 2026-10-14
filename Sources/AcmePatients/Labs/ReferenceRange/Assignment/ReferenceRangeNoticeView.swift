import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range notice.
    final class ReferenceRangeNoticeView {
        var codeText: String
        var label: String
        var limit: String
        var unit: String
        var capacity: String
        var allergy: String
        var patientRef: String
        var statusLabel: String

        init(codeText: String, label: String, limit: String, unit: String, capacity: String, allergy: String, patientRef: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.limit = limit
            self.unit = unit
            self.capacity = capacity
            self.allergy = allergy
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeNoticeView(_ item: ReferenceRangeNotice) -> ReferenceRangeNoticeView {
        return ReferenceRangeNoticeView(
            codeText: item.code,
            label: item.label,
            limit: String(item.limit),
            unit: Kit.Text.truncate(item.unit, limit: 120),
            capacity: String(item.capacity),
            allergy: item.allergy,
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeNoticeViews(_ items: [ReferenceRangeNotice]) -> [ReferenceRangeNoticeView] {
        var views: [ReferenceRangeNoticeView] = []
        for item in items {
            views.append(toReferenceRangeNoticeView(item))
        }
        return views
    }

    static func sumReferenceRangeNoticeView(_ view: ReferenceRangeNoticeView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedLimit) + Double(parsedCapacity)
    }
}
