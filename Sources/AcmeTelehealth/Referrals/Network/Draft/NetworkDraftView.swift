import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network draft.
    final class NetworkDraftView {
        var code: String
        var nameText: String
        var regionText: String
        var batchSize: String
        var summary: String
        var sequence: String
        var ward: String
        var ratio: String
        var statusLabel: String

        init(code: String, nameText: String, regionText: String, batchSize: String, summary: String, sequence: String, ward: String, ratio: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.regionText = regionText
            self.batchSize = batchSize
            self.summary = summary
            self.sequence = sequence
            self.ward = ward
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkDraftView(_ item: NetworkDraft) -> NetworkDraftView {
        return NetworkDraftView(
            code: item.code,
            nameText: item.name,
            regionText: item.region,
            batchSize: String(item.batchSize),
            summary: Kit.Text.truncate(item.summary, limit: 120),
            sequence: String(item.sequence),
            ward: item.ward,
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkDraftViews(_ items: [NetworkDraft]) -> [NetworkDraftView] {
        var views: [NetworkDraftView] = []
        for item in items {
            views.append(toNetworkDraftView(item))
        }
        return views
    }

    static func sumNetworkDraftView(_ view: NetworkDraftView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedSequence) + parsedRatio
    }
}
