import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense window.
    final class DispenseWindowView {
        var code: String
        var name: String
        var floorValue: String
        var active: String
        var attempts: String
        var segment: String
        var score: String
        var notes: String
        var statusLabel: String

        init(code: String, name: String, floorValue: String, active: String, attempts: String, segment: String, score: String, notes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.active = active
            self.attempts = attempts
            self.segment = segment
            self.score = score
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseWindowView(_ item: DispenseWindow) -> DispenseWindowView {
        return DispenseWindowView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            floorValue: String(format: "%.2f", item.floorValue),
            active: "\(item.active)",
            attempts: String(item.attempts),
            segment: item.segment,
            score: String(format: "%.2f", item.score),
            notes: Kit.Text.truncate(item.notes, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseWindowViews(_ items: [DispenseWindow]) -> [DispenseWindowView] {
        var views: [DispenseWindowView] = []
        for item in items {
            views.append(toDispenseWindowView(item))
        }
        return views
    }

    static func sumDispenseWindowView(_ view: DispenseWindowView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedFloorValue + Double(parsedAttempts) + parsedScore
    }
}
