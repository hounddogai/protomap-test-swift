import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a seasonal handoff window.
    final class SeasonalHandoffWindowView {
        var code: String
        var label: String
        var sequenceText: String
        var capacity: String
        var notes: String
        var createdAt: String
        var floorValue: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, label: String, sequenceText: String, capacity: String, notes: String, createdAt: String, floorValue: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.sequenceText = sequenceText
            self.capacity = capacity
            self.notes = notes
            self.createdAt = createdAt
            self.floorValue = floorValue
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalHandoffWindowView(_ item: SeasonalHandoffWindow) -> SeasonalHandoffWindowView {
        return SeasonalHandoffWindowView(
            code: item.code,
            label: item.label,
            sequenceText: String(item.sequence),
            capacity: String(item.capacity),
            notes: Kit.Text.truncate(item.notes, limit: 120),
            createdAt: String(item.createdAt),
            floorValue: String(format: "%.2f", item.floorValue),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalHandoffWindowViews(_ items: [SeasonalHandoffWindow]) -> [SeasonalHandoffWindowView] {
        var views: [SeasonalHandoffWindowView] = []
        for item in items {
            views.append(toSeasonalHandoffWindowView(item))
        }
        return views
    }

    static func sumSeasonalHandoffWindowView(_ view: SeasonalHandoffWindowView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedSequence) + Double(parsedCapacity) + Double(parsedCreatedAt)
    }
}
