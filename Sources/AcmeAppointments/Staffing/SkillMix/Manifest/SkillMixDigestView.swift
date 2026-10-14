import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix digest.
    final class SkillMixDigestView {
        var codeText: String
        var labelText: String
        var maximum: String
        var ownerID: String
        var visibleText: String
        var segmentText: String
        var patientRef: String
        var channel: String
        var statusLabel: String

        init(codeText: String, labelText: String, maximum: String, ownerID: String, visibleText: String, segmentText: String, patientRef: String, channel: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.maximum = maximum
            self.ownerID = ownerID
            self.visibleText = visibleText
            self.segmentText = segmentText
            self.patientRef = patientRef
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixDigestView(_ item: SkillMixDigest) -> SkillMixDigestView {
        return SkillMixDigestView(
            codeText: item.code,
            labelText: item.label,
            maximum: String(format: "%.2f", item.maximum),
            ownerID: item.ownerID,
            visibleText: "\(item.visible)",
            segmentText: item.segment,
            patientRef: item.patientRef,
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixDigestViews(_ items: [SkillMixDigest]) -> [SkillMixDigestView] {
        var views: [SkillMixDigestView] = []
        for item in items {
            views.append(toSkillMixDigestView(item))
        }
        return views
    }

    static func sumSkillMixDigestView(_ view: SkillMixDigestView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
