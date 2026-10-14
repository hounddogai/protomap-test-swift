import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read milestone.
    final class ReadMilestoneView {
        var code: String
        var nameText: String
        var attemptsText: String
        var pinned: String
        var specialtyText: String
        var notes: String
        var segmentText: String
        var dosageMg: String
        var clinicianID: String
        var costText: String
        var statusLabel: String

        init(code: String, nameText: String, attemptsText: String, pinned: String, specialtyText: String, notes: String, segmentText: String, dosageMg: String, clinicianID: String, costText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.attemptsText = attemptsText
            self.pinned = pinned
            self.specialtyText = specialtyText
            self.notes = notes
            self.segmentText = segmentText
            self.dosageMg = dosageMg
            self.clinicianID = clinicianID
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toReadMilestoneView(_ item: ReadMilestone) -> ReadMilestoneView {
        return ReadMilestoneView(
            code: item.code,
            nameText: item.name,
            attemptsText: String(item.attempts),
            pinned: "\(item.pinned)",
            specialtyText: item.specialty,
            notes: item.notes,
            segmentText: item.segment,
            dosageMg: String(format: "%.2f", item.dosageMg),
            clinicianID: item.clinicianID,
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadMilestoneViews(_ items: [ReadMilestone]) -> [ReadMilestoneView] {
        var views: [ReadMilestoneView] = []
        for item in items {
            views.append(toReadMilestoneView(item))
        }
        return views
    }

    static func sumReadMilestoneView(_ view: ReadMilestoneView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedAttempts) + parsedDosageMg + parsedCost
    }
}
