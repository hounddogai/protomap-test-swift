import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a global statement estimate.
    final class GlobalStatementEstimateView {
        var code: String
        var label: String
        var retries: String
        var approvedText: String
        var minimum: String
        var durationMinutes: String
        var clinicianID: String
        var active: String
        var patientRef: String
        var refills: String
        var createdAt: String
        var statusLabel: String

        init(code: String, label: String, retries: String, approvedText: String, minimum: String, durationMinutes: String, clinicianID: String, active: String, patientRef: String, refills: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.retries = retries
            self.approvedText = approvedText
            self.minimum = minimum
            self.durationMinutes = durationMinutes
            self.clinicianID = clinicianID
            self.active = active
            self.patientRef = patientRef
            self.refills = refills
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalStatementEstimateView(_ item: GlobalStatementEstimate) -> GlobalStatementEstimateView {
        return GlobalStatementEstimateView(
            code: item.code,
            label: item.label,
            retries: String(item.retries),
            approvedText: "\(item.approved)",
            minimum: String(format: "%.2f", item.minimum),
            durationMinutes: String(item.durationMinutes),
            clinicianID: item.clinicianID,
            active: "\(item.active)",
            patientRef: item.patientRef,
            refills: String(item.refills),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalStatementEstimateViews(_ items: [GlobalStatementEstimate]) -> [GlobalStatementEstimateView] {
        var views: [GlobalStatementEstimateView] = []
        for item in items {
            views.append(toGlobalStatementEstimateView(item))
        }
        return views
    }

    static func sumGlobalStatementEstimateView(_ view: GlobalStatementEstimateView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedRetries) + parsedMinimum + Double(parsedDurationMinutes)
    }
}
