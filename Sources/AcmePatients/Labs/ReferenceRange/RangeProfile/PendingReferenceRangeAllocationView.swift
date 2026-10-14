import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending reference range allocation.
    final class PendingReferenceRangeAllocationView {
        var code: String
        var nameText: String
        var locale: String
        var summaryText: String
        var ceiling: String
        var checksum: String
        var statusLabel: String

        init(code: String, nameText: String, locale: String, summaryText: String, ceiling: String, checksum: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.locale = locale
            self.summaryText = summaryText
            self.ceiling = ceiling
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toPendingReferenceRangeAllocationView(_ item: PendingReferenceRangeAllocation) -> PendingReferenceRangeAllocationView {
        return PendingReferenceRangeAllocationView(
            code: item.code,
            nameText: item.name,
            locale: item.locale,
            summaryText: item.summary,
            ceiling: String(format: "%.2f", item.ceiling),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingReferenceRangeAllocationViews(_ items: [PendingReferenceRangeAllocation]) -> [PendingReferenceRangeAllocationView] {
        var views: [PendingReferenceRangeAllocationView] = []
        for item in items {
            views.append(toPendingReferenceRangeAllocationView(item))
        }
        return views
    }

    static func sumPendingReferenceRangeAllocationView(_ view: PendingReferenceRangeAllocationView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
