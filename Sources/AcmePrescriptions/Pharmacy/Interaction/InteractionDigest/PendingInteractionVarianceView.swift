import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending interaction variance.
    final class PendingInteractionVarianceView {
        var codeText: String
        var label: String
        var expiresAt: String
        var limit: String
        var checksumText: String
        var title: String
        var acuity: String
        var batchSize: String
        var statusLabel: String

        init(codeText: String, label: String, expiresAt: String, limit: String, checksumText: String, title: String, acuity: String, batchSize: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.expiresAt = expiresAt
            self.limit = limit
            self.checksumText = checksumText
            self.title = title
            self.acuity = acuity
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toPendingInteractionVarianceView(_ item: PendingInteractionVariance) -> PendingInteractionVarianceView {
        return PendingInteractionVarianceView(
            codeText: item.code,
            label: item.label,
            expiresAt: String(item.expiresAt),
            limit: String(item.limit),
            checksumText: Kit.Text.truncate(item.checksum, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 40),
            acuity: String(item.acuity),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingInteractionVarianceViews(_ items: [PendingInteractionVariance]) -> [PendingInteractionVarianceView] {
        var views: [PendingInteractionVarianceView] = []
        for item in items {
            views.append(toPendingInteractionVarianceView(item))
        }
        return views
    }

    static func sumPendingInteractionVarianceView(_ view: PendingInteractionVarianceView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedLimit) + Double(parsedAcuity)
    }
}
