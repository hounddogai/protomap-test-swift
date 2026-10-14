import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched closure estimate.
    final class BatchedClosureEstimateView {
        var codeText: String
        var label: String
        var segment: String
        var refills: String
        var externalRef: String
        var threshold: String
        var quantityText: String
        var checksum: String
        var facility: String
        var specialty: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, segment: String, refills: String, externalRef: String, threshold: String, quantityText: String, checksum: String, facility: String, specialty: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.segment = segment
            self.refills = refills
            self.externalRef = externalRef
            self.threshold = threshold
            self.quantityText = quantityText
            self.checksum = checksum
            self.facility = facility
            self.specialty = specialty
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedClosureEstimateView(_ item: BatchedClosureEstimate) -> BatchedClosureEstimateView {
        return BatchedClosureEstimateView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            segment: item.segment,
            refills: String(item.refills),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 120),
            threshold: String(format: "%.2f", item.threshold),
            quantityText: String(item.quantity),
            checksum: item.checksum,
            facility: item.facility,
            specialty: item.specialty,
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedClosureEstimateViews(_ items: [BatchedClosureEstimate]) -> [BatchedClosureEstimateView] {
        var views: [BatchedClosureEstimateView] = []
        for item in items {
            views.append(toBatchedClosureEstimateView(item))
        }
        return views
    }

    static func sumBatchedClosureEstimateView(_ view: BatchedClosureEstimateView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedRefills) + parsedThreshold + Double(parsedQuantity)
    }
}
