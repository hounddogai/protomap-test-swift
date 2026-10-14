import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read batch.
    final class ReadBatchView {
        var code: String
        var name: String
        var attempts: String
        var capacity: String
        var segment: String
        var pinned: String
        var statusLabel: String

        init(code: String, name: String, attempts: String, capacity: String, segment: String, pinned: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.capacity = capacity
            self.segment = segment
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toReadBatchView(_ item: ReadBatch) -> ReadBatchView {
        return ReadBatchView(
            code: item.code,
            name: item.name,
            attempts: String(item.attempts),
            capacity: String(item.capacity),
            segment: item.segment,
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadBatchViews(_ items: [ReadBatch]) -> [ReadBatchView] {
        var views: [ReadBatchView] = []
        for item in items {
            views.append(toReadBatchView(item))
        }
        return views
    }

    static func sumReadBatchView(_ view: ReadBatchView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedAttempts) + Double(parsedCapacity)
    }
}
