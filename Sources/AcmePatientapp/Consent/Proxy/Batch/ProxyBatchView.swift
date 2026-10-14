import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy batch.
    final class ProxyBatchView {
        var code: String
        var label: String
        var visitMinutes: String
        var scoreText: String
        var capacity: String
        var maximum: String
        var allergy: String
        var minimum: String
        var attempts: String
        var checksum: String
        var statusLabel: String

        init(code: String, label: String, visitMinutes: String, scoreText: String, capacity: String, maximum: String, allergy: String, minimum: String, attempts: String, checksum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.scoreText = scoreText
            self.capacity = capacity
            self.maximum = maximum
            self.allergy = allergy
            self.minimum = minimum
            self.attempts = attempts
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toProxyBatchView(_ item: ProxyBatch) -> ProxyBatchView {
        return ProxyBatchView(
            code: item.code,
            label: item.label,
            visitMinutes: String(item.visitMinutes),
            scoreText: String(format: "%.2f", item.score),
            capacity: String(item.capacity),
            maximum: String(format: "%.2f", item.maximum),
            allergy: item.allergy,
            minimum: String(format: "%.2f", item.minimum),
            attempts: String(item.attempts),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyBatchViews(_ items: [ProxyBatch]) -> [ProxyBatchView] {
        var views: [ProxyBatchView] = []
        for item in items {
            views.append(toProxyBatchView(item))
        }
        return views
    }

    static func sumProxyBatchView(_ view: ProxyBatchView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedVisitMinutes) + parsedScore + Double(parsedCapacity)
    }
}
