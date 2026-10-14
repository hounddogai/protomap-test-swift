import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a batched dispense bundle.
    final class BatchedDispenseBundleView {
        var codeText: String
        var label: String
        var facility: String
        var regionText: String
        var timezoneText: String
        var retries: String
        var scoreText: String
        var createdAt: String
        var active: String
        var patientRef: String
        var windowDaysText: String
        var statusLabel: String

        init(codeText: String, label: String, facility: String, regionText: String, timezoneText: String, retries: String, scoreText: String, createdAt: String, active: String, patientRef: String, windowDaysText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.facility = facility
            self.regionText = regionText
            self.timezoneText = timezoneText
            self.retries = retries
            self.scoreText = scoreText
            self.createdAt = createdAt
            self.active = active
            self.patientRef = patientRef
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDispenseBundleView(_ item: BatchedDispenseBundle) -> BatchedDispenseBundleView {
        return BatchedDispenseBundleView(
            codeText: item.code,
            label: item.label,
            facility: Kit.Text.truncate(item.facility, limit: 40),
            regionText: item.region,
            timezoneText: item.timezone,
            retries: String(item.retries),
            scoreText: String(format: "%.2f", item.score),
            createdAt: String(item.createdAt),
            active: "\(item.active)",
            patientRef: item.patientRef,
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDispenseBundleViews(_ items: [BatchedDispenseBundle]) -> [BatchedDispenseBundleView] {
        var views: [BatchedDispenseBundleView] = []
        for item in items {
            views.append(toBatchedDispenseBundleView(item))
        }
        return views
    }

    static func sumBatchedDispenseBundleView(_ view: BatchedDispenseBundleView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedRetries) + parsedScore + Double(parsedCreatedAt)
    }
}
