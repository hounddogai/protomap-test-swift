import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a capped skill mix checkpoint.
    final class CappedSkillMixCheckpointView {
        var codeText: String
        var nameText: String
        var dosageMgText: String
        var versionText: String
        var sequence: String
        var ratio: String
        var threshold: String
        var createdAt: String
        var startsAt: String
        var encounterIDText: String
        var statusLabel: String

        init(codeText: String, nameText: String, dosageMgText: String, versionText: String, sequence: String, ratio: String, threshold: String, createdAt: String, startsAt: String, encounterIDText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.dosageMgText = dosageMgText
            self.versionText = versionText
            self.sequence = sequence
            self.ratio = ratio
            self.threshold = threshold
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedSkillMixCheckpointView(_ item: CappedSkillMixCheckpoint) -> CappedSkillMixCheckpointView {
        return CappedSkillMixCheckpointView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            versionText: String(item.version),
            sequence: String(item.sequence),
            ratio: String(format: "%.2f", item.ratio),
            threshold: String(format: "%.2f", item.threshold),
            createdAt: String(item.createdAt),
            startsAt: String(item.startsAt),
            encounterIDText: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedSkillMixCheckpointViews(_ items: [CappedSkillMixCheckpoint]) -> [CappedSkillMixCheckpointView] {
        var views: [CappedSkillMixCheckpointView] = []
        for item in items {
            views.append(toCappedSkillMixCheckpointView(item))
        }
        return views
    }

    static func sumCappedSkillMixCheckpointView(_ view: CappedSkillMixCheckpointView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedDosageMg + Double(parsedVersion) + Double(parsedSequence)
    }
}
