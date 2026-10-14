import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a scheduled overtime record.
    final class ScheduledOvertimeRecordView {
        var code: String
        var label: String
        var facility: String
        var ratio: String
        var ward: String
        var updatedAt: String
        var discountText: String
        var revisionText: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, label: String, facility: String, ratio: String, ward: String, updatedAt: String, discountText: String, revisionText: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.facility = facility
            self.ratio = ratio
            self.ward = ward
            self.updatedAt = updatedAt
            self.discountText = discountText
            self.revisionText = revisionText
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledOvertimeRecordView(_ item: ScheduledOvertimeRecord) -> ScheduledOvertimeRecordView {
        return ScheduledOvertimeRecordView(
            code: item.code,
            label: item.label,
            facility: item.facility,
            ratio: String(format: "%.2f", item.ratio),
            ward: item.ward,
            updatedAt: String(item.updatedAt),
            discountText: String(format: "%.2f", item.discount),
            revisionText: String(item.revision),
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledOvertimeRecordViews(_ items: [ScheduledOvertimeRecord]) -> [ScheduledOvertimeRecordView] {
        var views: [ScheduledOvertimeRecordView] = []
        for item in items {
            views.append(toScheduledOvertimeRecordView(item))
        }
        return views
    }

    static func sumScheduledOvertimeRecordView(_ view: ScheduledOvertimeRecordView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedRatio + Double(parsedUpdatedAt) + parsedDiscount
    }
}
