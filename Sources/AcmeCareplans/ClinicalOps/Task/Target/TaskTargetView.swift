import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task target.
    final class TaskTargetView {
        var code: String
        var label: String
        var rate: String
        var reviewerText: String
        var floorValue: String
        var ownerID: String
        var facility: String
        var regionText: String
        var statusLabel: String

        init(code: String, label: String, rate: String, reviewerText: String, floorValue: String, ownerID: String, facility: String, regionText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.rate = rate
            self.reviewerText = reviewerText
            self.floorValue = floorValue
            self.ownerID = ownerID
            self.facility = facility
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toTaskTargetView(_ item: TaskTarget) -> TaskTargetView {
        return TaskTargetView(
            code: item.code,
            label: item.label,
            rate: String(format: "%.2f", item.rate),
            reviewerText: item.reviewer,
            floorValue: String(format: "%.2f", item.floorValue),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            facility: item.facility,
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskTargetViews(_ items: [TaskTarget]) -> [TaskTargetView] {
        var views: [TaskTargetView] = []
        for item in items {
            views.append(toTaskTargetView(item))
        }
        return views
    }

    static func sumTaskTargetView(_ view: TaskTargetView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedRate + parsedFloorValue
    }
}
