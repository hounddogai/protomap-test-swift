import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier allocation.
    final class CourierAllocationView {
        var code: String
        var titleText: String
        var contactEmail: String
        var segmentText: String
        var margin: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, titleText: String, contactEmail: String, segmentText: String, margin: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.contactEmail = contactEmail
            self.segmentText = segmentText
            self.margin = margin
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toCourierAllocationView(_ item: CourierAllocation) -> CourierAllocationView {
        return CourierAllocationView(
            code: item.code,
            titleText: item.title,
            contactEmail: item.contactEmail,
            segmentText: item.segment,
            margin: String(format: "%.2f", item.margin),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierAllocationViews(_ items: [CourierAllocation]) -> [CourierAllocationView] {
        var views: [CourierAllocationView] = []
        for item in items {
            views.append(toCourierAllocationView(item))
        }
        return views
    }

    static func sumCourierAllocationView(_ view: CourierAllocationView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedMargin + parsedDosageMg
    }
}
