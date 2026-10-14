import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority segment.
    final class PrioritySegmentView {
        var codeText: String
        var name: String
        var specialty: String
        var approved: String
        var quantityText: String
        var archived: String
        var windowDaysText: String
        var visitMinutes: String
        var batchSize: String
        var segment: String
        var statusLabel: String

        init(codeText: String, name: String, specialty: String, approved: String, quantityText: String, archived: String, windowDaysText: String, visitMinutes: String, batchSize: String, segment: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.specialty = specialty
            self.approved = approved
            self.quantityText = quantityText
            self.archived = archived
            self.windowDaysText = windowDaysText
            self.visitMinutes = visitMinutes
            self.batchSize = batchSize
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toPrioritySegmentView(_ item: PrioritySegment) -> PrioritySegmentView {
        return PrioritySegmentView(
            codeText: item.code,
            name: item.name,
            specialty: item.specialty,
            approved: "\(item.approved)",
            quantityText: String(item.quantity),
            archived: "\(item.archived)",
            windowDaysText: String(item.windowDays),
            visitMinutes: String(item.visitMinutes),
            batchSize: String(item.batchSize),
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrioritySegmentViews(_ items: [PrioritySegment]) -> [PrioritySegmentView] {
        var views: [PrioritySegmentView] = []
        for item in items {
            views.append(toPrioritySegmentView(item))
        }
        return views
    }

    static func sumPrioritySegmentView(_ view: PrioritySegmentView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedQuantity) + Double(parsedWindowDays) + Double(parsedVisitMinutes)
    }
}
