import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a default recall checkpoint.
    final class DefaultRecallCheckpointView {
        var codeText: String
        var nameText: String
        var diagnosisCodeText: String
        var minimumText: String
        var startsAt: String
        var limit: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, nameText: String, diagnosisCodeText: String, minimumText: String, startsAt: String, limit: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.diagnosisCodeText = diagnosisCodeText
            self.minimumText = minimumText
            self.startsAt = startsAt
            self.limit = limit
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultRecallCheckpointView(_ item: DefaultRecallCheckpoint) -> DefaultRecallCheckpointView {
        return DefaultRecallCheckpointView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            diagnosisCodeText: item.diagnosisCode,
            minimumText: String(format: "%.2f", item.minimum),
            startsAt: String(item.startsAt),
            limit: String(item.limit),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultRecallCheckpointViews(_ items: [DefaultRecallCheckpoint]) -> [DefaultRecallCheckpointView] {
        var views: [DefaultRecallCheckpointView] = []
        for item in items {
            views.append(toDefaultRecallCheckpointView(item))
        }
        return views
    }

    static func sumDefaultRecallCheckpointView(_ view: DefaultRecallCheckpointView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedMinimum + Double(parsedStartsAt) + Double(parsedLimit)
    }
}
