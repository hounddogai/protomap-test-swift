import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study checkpoint.
    final class StudyCheckpointView {
        var code: String
        var name: String
        var budget: String
        var ward: String
        var createdAt: String
        var statusLabel: String

        init(code: String, name: String, budget: String, ward: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.budget = budget
            self.ward = ward
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toStudyCheckpointView(_ item: StudyCheckpoint) -> StudyCheckpointView {
        return StudyCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            budget: String(format: "%.2f", item.budget),
            ward: item.ward,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyCheckpointViews(_ items: [StudyCheckpoint]) -> [StudyCheckpointView] {
        var views: [StudyCheckpointView] = []
        for item in items {
            views.append(toStudyCheckpointView(item))
        }
        return views
    }

    static func sumStudyCheckpointView(_ view: StudyCheckpointView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedBudget + Double(parsedCreatedAt)
    }
}
