import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a capped study slot.
    final class CappedStudySlotView {
        var codeText: String
        var title: String
        var attempts: String
        var acuity: String
        var margin: String
        var statusLabel: String

        init(codeText: String, title: String, attempts: String, acuity: String, margin: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.attempts = attempts
            self.acuity = acuity
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toCappedStudySlotView(_ item: CappedStudySlot) -> CappedStudySlotView {
        return CappedStudySlotView(
            codeText: item.code,
            title: item.title,
            attempts: String(item.attempts),
            acuity: String(item.acuity),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedStudySlotViews(_ items: [CappedStudySlot]) -> [CappedStudySlotView] {
        var views: [CappedStudySlotView] = []
        for item in items {
            views.append(toCappedStudySlotView(item))
        }
        return views
    }

    static func sumCappedStudySlotView(_ view: CappedStudySlotView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedAttempts) + Double(parsedAcuity) + parsedMargin
    }
}
