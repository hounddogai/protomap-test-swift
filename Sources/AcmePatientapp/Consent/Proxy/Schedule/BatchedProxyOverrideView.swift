import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched proxy override.
    final class BatchedProxyOverrideView {
        var codeText: String
        var label: String
        var externalRef: String
        var facility: String
        var startsAtText: String
        var dosageMg: String
        var patientRef: String
        var margin: String
        var retries: String
        var rate: String
        var statusLabel: String

        init(codeText: String, label: String, externalRef: String, facility: String, startsAtText: String, dosageMg: String, patientRef: String, margin: String, retries: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.externalRef = externalRef
            self.facility = facility
            self.startsAtText = startsAtText
            self.dosageMg = dosageMg
            self.patientRef = patientRef
            self.margin = margin
            self.retries = retries
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedProxyOverrideView(_ item: BatchedProxyOverride) -> BatchedProxyOverrideView {
        return BatchedProxyOverrideView(
            codeText: item.code,
            label: item.label,
            externalRef: item.externalRef,
            facility: item.facility,
            startsAtText: String(item.startsAt),
            dosageMg: String(format: "%.2f", item.dosageMg),
            patientRef: item.patientRef,
            margin: String(format: "%.2f", item.margin),
            retries: String(item.retries),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedProxyOverrideViews(_ items: [BatchedProxyOverride]) -> [BatchedProxyOverrideView] {
        var views: [BatchedProxyOverrideView] = []
        for item in items {
            views.append(toBatchedProxyOverrideView(item))
        }
        return views
    }

    static func sumBatchedProxyOverrideView(_ view: BatchedProxyOverrideView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedStartsAt) + parsedDosageMg + parsedMargin
    }
}
