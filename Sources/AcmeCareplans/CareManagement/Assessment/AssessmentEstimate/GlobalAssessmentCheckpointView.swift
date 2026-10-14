import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global assessment checkpoint.
    final class GlobalAssessmentCheckpointView {
        var codeText: String
        var nameText: String
        var createdAt: String
        var visible: String
        var version: String
        var statusLabel: String

        init(codeText: String, nameText: String, createdAt: String, visible: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.createdAt = createdAt
            self.visible = visible
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalAssessmentCheckpointView(_ item: GlobalAssessmentCheckpoint) -> GlobalAssessmentCheckpointView {
        return GlobalAssessmentCheckpointView(
            codeText: item.code,
            nameText: item.name,
            createdAt: String(item.createdAt),
            visible: "\(item.visible)",
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalAssessmentCheckpointViews(_ items: [GlobalAssessmentCheckpoint]) -> [GlobalAssessmentCheckpointView] {
        var views: [GlobalAssessmentCheckpointView] = []
        for item in items {
            views.append(toGlobalAssessmentCheckpointView(item))
        }
        return views
    }

    static func sumGlobalAssessmentCheckpointView(_ view: GlobalAssessmentCheckpointView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedVersion)
    }
}
