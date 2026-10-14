import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift batch.
    final class ShiftBatchView {
        var codeText: String
        var name: String
        var pinnedText: String
        var endsAt: String
        var visitMinutes: String
        var title: String
        var statusLabel: String

        init(codeText: String, name: String, pinnedText: String, endsAt: String, visitMinutes: String, title: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.pinnedText = pinnedText
            self.endsAt = endsAt
            self.visitMinutes = visitMinutes
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toShiftBatchView(_ item: ShiftBatch) -> ShiftBatchView {
        return ShiftBatchView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            pinnedText: "\(item.pinned)",
            endsAt: String(item.endsAt),
            visitMinutes: String(item.visitMinutes),
            title: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftBatchViews(_ items: [ShiftBatch]) -> [ShiftBatchView] {
        var views: [ShiftBatchView] = []
        for item in items {
            views.append(toShiftBatchView(item))
        }
        return views
    }

    static func sumShiftBatchView(_ view: ShiftBatchView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedVisitMinutes)
    }
}
