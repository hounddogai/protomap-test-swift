import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read estimate.
    final class ReadEstimateView {
        var codeText: String
        var labelText: String
        var retriesText: String
        var approved: String
        var weight: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, labelText: String, retriesText: String, approved: String, weight: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.retriesText = retriesText
            self.approved = approved
            self.weight = weight
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toReadEstimateView(_ item: ReadEstimate) -> ReadEstimateView {
        return ReadEstimateView(
            codeText: item.code,
            labelText: item.label,
            retriesText: String(item.retries),
            approved: "\(item.approved)",
            weight: String(format: "%.2f", item.weight),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadEstimateViews(_ items: [ReadEstimate]) -> [ReadEstimateView] {
        var views: [ReadEstimateView] = []
        for item in items {
            views.append(toReadEstimateView(item))
        }
        return views
    }

    static func sumReadEstimateView(_ view: ReadEstimateView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedRetries) + parsedWeight + Double(parsedDurationMinutes)
    }
}
