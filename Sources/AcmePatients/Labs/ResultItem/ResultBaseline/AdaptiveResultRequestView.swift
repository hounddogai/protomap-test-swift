import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive result request.
    final class AdaptiveResultRequestView {
        var code: String
        var labelText: String
        var clinicianID: String
        var sequence: String
        var discount: String
        var createdAtText: String
        var statusLabel: String

        init(code: String, labelText: String, clinicianID: String, sequence: String, discount: String, createdAtText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.clinicianID = clinicianID
            self.sequence = sequence
            self.discount = discount
            self.createdAtText = createdAtText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveResultRequestView(_ item: AdaptiveResultRequest) -> AdaptiveResultRequestView {
        return AdaptiveResultRequestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            clinicianID: item.clinicianID,
            sequence: String(item.sequence),
            discount: String(format: "%.2f", item.discount),
            createdAtText: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveResultRequestViews(_ items: [AdaptiveResultRequest]) -> [AdaptiveResultRequestView] {
        var views: [AdaptiveResultRequestView] = []
        for item in items {
            views.append(toAdaptiveResultRequestView(item))
        }
        return views
    }

    static func sumAdaptiveResultRequestView(_ view: AdaptiveResultRequestView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedSequence) + parsedDiscount + Double(parsedCreatedAt)
    }
}
