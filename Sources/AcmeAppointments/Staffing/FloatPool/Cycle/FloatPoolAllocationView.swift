import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool allocation.
    final class FloatPoolAllocationView {
        var code: String
        var title: String
        var sequenceText: String
        var ward: String
        var archived: String
        var margin: String
        var priority: String
        var descriptionText: String
        var batchSizeText: String
        var statusLabel: String

        init(code: String, title: String, sequenceText: String, ward: String, archived: String, margin: String, priority: String, descriptionText: String, batchSizeText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sequenceText = sequenceText
            self.ward = ward
            self.archived = archived
            self.margin = margin
            self.priority = priority
            self.descriptionText = descriptionText
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolAllocationView(_ item: FloatPoolAllocation) -> FloatPoolAllocationView {
        return FloatPoolAllocationView(
            code: item.code,
            title: item.title,
            sequenceText: String(item.sequence),
            ward: Kit.Text.truncate(item.ward, limit: 80),
            archived: "\(item.archived)",
            margin: String(format: "%.2f", item.margin),
            priority: String(item.priority),
            descriptionText: item.description,
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolAllocationViews(_ items: [FloatPoolAllocation]) -> [FloatPoolAllocationView] {
        var views: [FloatPoolAllocationView] = []
        for item in items {
            views.append(toFloatPoolAllocationView(item))
        }
        return views
    }

    static func sumFloatPoolAllocationView(_ view: FloatPoolAllocationView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedSequence) + parsedMargin + Double(parsedPriority)
    }
}
