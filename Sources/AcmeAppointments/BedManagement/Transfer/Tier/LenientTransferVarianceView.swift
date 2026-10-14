import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient transfer variance.
    final class LenientTransferVarianceView {
        var codeText: String
        var title: String
        var maximum: String
        var priority: String
        var endsAt: String
        var specialtyText: String
        var statusLabel: String

        init(codeText: String, title: String, maximum: String, priority: String, endsAt: String, specialtyText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.maximum = maximum
            self.priority = priority
            self.endsAt = endsAt
            self.specialtyText = specialtyText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientTransferVarianceView(_ item: LenientTransferVariance) -> LenientTransferVarianceView {
        return LenientTransferVarianceView(
            codeText: item.code,
            title: item.title,
            maximum: String(format: "%.2f", item.maximum),
            priority: String(item.priority),
            endsAt: String(item.endsAt),
            specialtyText: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientTransferVarianceViews(_ items: [LenientTransferVariance]) -> [LenientTransferVarianceView] {
        var views: [LenientTransferVarianceView] = []
        for item in items {
            views.append(toLenientTransferVarianceView(item))
        }
        return views
    }

    static func sumLenientTransferVarianceView(_ view: LenientTransferVarianceView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedMaximum + Double(parsedPriority) + Double(parsedEndsAt)
    }
}
