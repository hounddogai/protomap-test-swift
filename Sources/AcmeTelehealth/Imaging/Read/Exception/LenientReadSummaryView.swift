import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient read summary.
    final class LenientReadSummaryView {
        var codeText: String
        var label: String
        var description: String
        var attemptsText: String
        var windowDays: String
        var weight: String
        var statusLabel: String

        init(codeText: String, label: String, description: String, attemptsText: String, windowDays: String, weight: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.description = description
            self.attemptsText = attemptsText
            self.windowDays = windowDays
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toLenientReadSummaryView(_ item: LenientReadSummary) -> LenientReadSummaryView {
        return LenientReadSummaryView(
            codeText: item.code,
            label: item.label,
            description: item.description,
            attemptsText: String(item.attempts),
            windowDays: String(item.windowDays),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientReadSummaryViews(_ items: [LenientReadSummary]) -> [LenientReadSummaryView] {
        var views: [LenientReadSummaryView] = []
        for item in items {
            views.append(toLenientReadSummaryView(item))
        }
        return views
    }

    static func sumLenientReadSummaryView(_ view: LenientReadSummaryView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedAttempts) + Double(parsedWindowDays) + parsedWeight
    }
}
