import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol window.
    final class CareProtocolWindowView {
        var codeText: String
        var label: String
        var margin: String
        var segmentText: String
        var maximum: String
        var weight: String
        var batchSize: String
        var attemptsText: String
        var notes: String
        var capacity: String
        var statusLabel: String

        init(codeText: String, label: String, margin: String, segmentText: String, maximum: String, weight: String, batchSize: String, attemptsText: String, notes: String, capacity: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.margin = margin
            self.segmentText = segmentText
            self.maximum = maximum
            self.weight = weight
            self.batchSize = batchSize
            self.attemptsText = attemptsText
            self.notes = notes
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolWindowView(_ item: CareProtocolWindow) -> CareProtocolWindowView {
        return CareProtocolWindowView(
            codeText: item.code,
            label: item.label,
            margin: String(format: "%.2f", item.margin),
            segmentText: item.segment,
            maximum: String(format: "%.2f", item.maximum),
            weight: String(format: "%.2f", item.weight),
            batchSize: String(item.batchSize),
            attemptsText: String(item.attempts),
            notes: item.notes,
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolWindowViews(_ items: [CareProtocolWindow]) -> [CareProtocolWindowView] {
        var views: [CareProtocolWindowView] = []
        for item in items {
            views.append(toCareProtocolWindowView(item))
        }
        return views
    }

    static func sumCareProtocolWindowView(_ view: CareProtocolWindowView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedMargin + parsedMaximum + parsedWeight
    }
}
