import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a manual care protocol slot.
    final class ManualCareProtocolSlotView {
        var codeText: String
        var label: String
        var description: String
        var pinned: String
        var procedureCodeText: String
        var threshold: String
        var scoreText: String
        var contactEmail: String
        var refills: String
        var allergyText: String
        var patientRefText: String
        var statusLabel: String

        init(codeText: String, label: String, description: String, pinned: String, procedureCodeText: String, threshold: String, scoreText: String, contactEmail: String, refills: String, allergyText: String, patientRefText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.description = description
            self.pinned = pinned
            self.procedureCodeText = procedureCodeText
            self.threshold = threshold
            self.scoreText = scoreText
            self.contactEmail = contactEmail
            self.refills = refills
            self.allergyText = allergyText
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toManualCareProtocolSlotView(_ item: ManualCareProtocolSlot) -> ManualCareProtocolSlotView {
        return ManualCareProtocolSlotView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            description: Kit.Text.truncate(item.description, limit: 64),
            pinned: "\(item.pinned)",
            procedureCodeText: item.procedureCode,
            threshold: String(format: "%.2f", item.threshold),
            scoreText: String(format: "%.2f", item.score),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            refills: String(item.refills),
            allergyText: item.allergy,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCareProtocolSlotViews(_ items: [ManualCareProtocolSlot]) -> [ManualCareProtocolSlotView] {
        var views: [ManualCareProtocolSlotView] = []
        for item in items {
            views.append(toManualCareProtocolSlotView(item))
        }
        return views
    }

    static func sumManualCareProtocolSlotView(_ view: ManualCareProtocolSlotView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedThreshold + parsedScore + Double(parsedRefills)
    }
}
