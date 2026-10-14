import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a batched accession estimate.
    final class BatchedAccessionEstimateView {
        var code: String
        var title: String
        var active: String
        var country: String
        var patientRef: String
        var procedureCode: String
        var refillsText: String
        var statusLabel: String

        init(code: String, title: String, active: String, country: String, patientRef: String, procedureCode: String, refillsText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.active = active
            self.country = country
            self.patientRef = patientRef
            self.procedureCode = procedureCode
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedAccessionEstimateView(_ item: BatchedAccessionEstimate) -> BatchedAccessionEstimateView {
        return BatchedAccessionEstimateView(
            code: item.code,
            title: item.title,
            active: "\(item.active)",
            country: item.country,
            patientRef: item.patientRef,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedAccessionEstimateViews(_ items: [BatchedAccessionEstimate]) -> [BatchedAccessionEstimateView] {
        var views: [BatchedAccessionEstimateView] = []
        for item in items {
            views.append(toBatchedAccessionEstimateView(item))
        }
        return views
    }

    static func sumBatchedAccessionEstimateView(_ view: BatchedAccessionEstimateView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedRefills)
    }
}
