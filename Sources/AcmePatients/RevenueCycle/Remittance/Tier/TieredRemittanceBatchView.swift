import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered remittance batch.
    final class TieredRemittanceBatchView {
        var codeText: String
        var nameText: String
        var bed: String
        var expiresAtText: String
        var specialty: String
        var reviewer: String
        var statusLabel: String

        init(codeText: String, nameText: String, bed: String, expiresAtText: String, specialty: String, reviewer: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.bed = bed
            self.expiresAtText = expiresAtText
            self.specialty = specialty
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRemittanceBatchView(_ item: TieredRemittanceBatch) -> TieredRemittanceBatchView {
        return TieredRemittanceBatchView(
            codeText: item.code,
            nameText: item.name,
            bed: item.bed,
            expiresAtText: String(item.expiresAt),
            specialty: Kit.Text.truncate(item.specialty, limit: 64),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRemittanceBatchViews(_ items: [TieredRemittanceBatch]) -> [TieredRemittanceBatchView] {
        var views: [TieredRemittanceBatchView] = []
        for item in items {
            views.append(toTieredRemittanceBatchView(item))
        }
        return views
    }

    static func sumTieredRemittanceBatchView(_ view: TieredRemittanceBatchView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
