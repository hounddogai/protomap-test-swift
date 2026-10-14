import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read policy.
    final class ReadPolicyView {
        var code: String
        var label: String
        var durationMinutesText: String
        var allergyText: String
        var notes: String
        var createdAtText: String
        var specialty: String
        var priority: String
        var statusLabel: String

        init(code: String, label: String, durationMinutesText: String, allergyText: String, notes: String, createdAtText: String, specialty: String, priority: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.durationMinutesText = durationMinutesText
            self.allergyText = allergyText
            self.notes = notes
            self.createdAtText = createdAtText
            self.specialty = specialty
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toReadPolicyView(_ item: ReadPolicy) -> ReadPolicyView {
        return ReadPolicyView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            durationMinutesText: String(item.durationMinutes),
            allergyText: Kit.Text.truncate(item.allergy, limit: 40),
            notes: item.notes,
            createdAtText: String(item.createdAt),
            specialty: Kit.Text.truncate(item.specialty, limit: 64),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadPolicyViews(_ items: [ReadPolicy]) -> [ReadPolicyView] {
        var views: [ReadPolicyView] = []
        for item in items {
            views.append(toReadPolicyView(item))
        }
        return views
    }

    static func sumReadPolicyView(_ view: ReadPolicyView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedCreatedAt) + Double(parsedPriority)
    }
}
