import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a capped transfer baseline.
    final class CappedTransferBaselineView {
        var code: String
        var title: String
        var capacity: String
        var checksum: String
        var batchSizeText: String
        var statusLabel: String

        init(code: String, title: String, capacity: String, checksum: String, batchSizeText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.checksum = checksum
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedTransferBaselineView(_ item: CappedTransferBaseline) -> CappedTransferBaselineView {
        return CappedTransferBaselineView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            capacity: String(item.capacity),
            checksum: item.checksum,
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedTransferBaselineViews(_ items: [CappedTransferBaseline]) -> [CappedTransferBaselineView] {
        var views: [CappedTransferBaselineView] = []
        for item in items {
            views.append(toCappedTransferBaselineView(item))
        }
        return views
    }

    static func sumCappedTransferBaselineView(_ view: CappedTransferBaselineView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedCapacity) + Double(parsedBatchSize)
    }
}
