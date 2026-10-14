import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling formulary snapshot.
    final class RollingFormularySnapshotView {
        var code: String
        var nameText: String
        var batchSize: String
        var createdAtText: String
        var region: String
        var score: String
        var ceilingText: String
        var currency: String
        var statusLabel: String

        init(code: String, nameText: String, batchSize: String, createdAtText: String, region: String, score: String, ceilingText: String, currency: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.batchSize = batchSize
            self.createdAtText = createdAtText
            self.region = region
            self.score = score
            self.ceilingText = ceilingText
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toRollingFormularySnapshotView(_ item: RollingFormularySnapshot) -> RollingFormularySnapshotView {
        return RollingFormularySnapshotView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            batchSize: String(item.batchSize),
            createdAtText: String(item.createdAt),
            region: item.region,
            score: String(format: "%.2f", item.score),
            ceilingText: String(format: "%.2f", item.ceiling),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingFormularySnapshotViews(_ items: [RollingFormularySnapshot]) -> [RollingFormularySnapshotView] {
        var views: [RollingFormularySnapshotView] = []
        for item in items {
            views.append(toRollingFormularySnapshotView(item))
        }
        return views
    }

    static func sumRollingFormularySnapshotView(_ view: RollingFormularySnapshotView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedCreatedAt) + parsedScore
    }
}
