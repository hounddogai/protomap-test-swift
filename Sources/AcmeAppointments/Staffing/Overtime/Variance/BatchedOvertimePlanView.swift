import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a batched overtime plan.
    final class BatchedOvertimePlanView {
        var code: String
        var name: String
        var patientRef: String
        var thresholdText: String
        var rate: String
        var segment: String
        var attempts: String
        var region: String
        var ceiling: String
        var statusLabel: String

        init(code: String, name: String, patientRef: String, thresholdText: String, rate: String, segment: String, attempts: String, region: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.thresholdText = thresholdText
            self.rate = rate
            self.segment = segment
            self.attempts = attempts
            self.region = region
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedOvertimePlanView(_ item: BatchedOvertimePlan) -> BatchedOvertimePlanView {
        return BatchedOvertimePlanView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            patientRef: item.patientRef,
            thresholdText: String(format: "%.2f", item.threshold),
            rate: String(format: "%.2f", item.rate),
            segment: Kit.Text.truncate(item.segment, limit: 40),
            attempts: String(item.attempts),
            region: item.region,
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedOvertimePlanViews(_ items: [BatchedOvertimePlan]) -> [BatchedOvertimePlanView] {
        var views: [BatchedOvertimePlanView] = []
        for item in items {
            views.append(toBatchedOvertimePlanView(item))
        }
        return views
    }

    static func sumBatchedOvertimePlanView(_ view: BatchedOvertimePlanView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedThreshold + parsedRate + Double(parsedAttempts)
    }
}
