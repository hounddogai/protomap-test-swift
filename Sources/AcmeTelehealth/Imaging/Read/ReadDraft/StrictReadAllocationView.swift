import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict read allocation.
    final class StrictReadAllocationView {
        var code: String
        var name: String
        var facility: String
        var batchSize: String
        var regionText: String
        var pinnedText: String
        var copayText: String
        var createdAt: String
        var rate: String
        var statusLabel: String

        init(code: String, name: String, facility: String, batchSize: String, regionText: String, pinnedText: String, copayText: String, createdAt: String, rate: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.facility = facility
            self.batchSize = batchSize
            self.regionText = regionText
            self.pinnedText = pinnedText
            self.copayText = copayText
            self.createdAt = createdAt
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toStrictReadAllocationView(_ item: StrictReadAllocation) -> StrictReadAllocationView {
        return StrictReadAllocationView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 40),
            facility: Kit.Text.truncate(item.facility, limit: 40),
            batchSize: String(item.batchSize),
            regionText: item.region,
            pinnedText: "\(item.pinned)",
            copayText: String(format: "%.2f", item.copay),
            createdAt: String(item.createdAt),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictReadAllocationViews(_ items: [StrictReadAllocation]) -> [StrictReadAllocationView] {
        var views: [StrictReadAllocationView] = []
        for item in items {
            views.append(toStrictReadAllocationView(item))
        }
        return views
    }

    static func sumStrictReadAllocationView(_ view: StrictReadAllocationView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedBatchSize) + parsedCopay + Double(parsedCreatedAt)
    }
}
