import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a default bed board variance.
    final class DefaultBedBoardVarianceView {
        var code: String
        var label: String
        var acuityText: String
        var capacity: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, label: String, acuityText: String, capacity: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.acuityText = acuityText
            self.capacity = capacity
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultBedBoardVarianceView(_ item: DefaultBedBoardVariance) -> DefaultBedBoardVarianceView {
        return DefaultBedBoardVarianceView(
            code: item.code,
            label: item.label,
            acuityText: String(item.acuity),
            capacity: String(item.capacity),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultBedBoardVarianceViews(_ items: [DefaultBedBoardVariance]) -> [DefaultBedBoardVarianceView] {
        var views: [DefaultBedBoardVarianceView] = []
        for item in items {
            views.append(toDefaultBedBoardVarianceView(item))
        }
        return views
    }

    static func sumDefaultBedBoardVarianceView(_ view: DefaultBedBoardVarianceView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedAcuity) + Double(parsedCapacity) + Double(parsedDurationMinutes)
    }
}
