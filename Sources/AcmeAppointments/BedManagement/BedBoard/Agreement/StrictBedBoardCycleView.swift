import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict bed board cycle.
    final class StrictBedBoardCycleView {
        var code: String
        var nameText: String
        var updatedAt: String
        var durationMinutes: String
        var pinned: String
        var maximum: String
        var patientRef: String
        var procedureCodeText: String
        var payer: String
        var diagnosisCodeText: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, nameText: String, updatedAt: String, durationMinutes: String, pinned: String, maximum: String, patientRef: String, procedureCodeText: String, payer: String, diagnosisCodeText: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.updatedAt = updatedAt
            self.durationMinutes = durationMinutes
            self.pinned = pinned
            self.maximum = maximum
            self.patientRef = patientRef
            self.procedureCodeText = procedureCodeText
            self.payer = payer
            self.diagnosisCodeText = diagnosisCodeText
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictBedBoardCycleView(_ item: StrictBedBoardCycle) -> StrictBedBoardCycleView {
        return StrictBedBoardCycleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: Kit.Text.truncate(item.name, limit: 40),
            updatedAt: String(item.updatedAt),
            durationMinutes: String(item.durationMinutes),
            pinned: "\(item.pinned)",
            maximum: String(format: "%.2f", item.maximum),
            patientRef: item.patientRef,
            procedureCodeText: item.procedureCode,
            payer: Kit.Text.truncate(item.payer, limit: 64),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictBedBoardCycleViews(_ items: [StrictBedBoardCycle]) -> [StrictBedBoardCycleView] {
        var views: [StrictBedBoardCycleView] = []
        for item in items {
            views.append(toStrictBedBoardCycleView(item))
        }
        return views
    }

    static func sumStrictBedBoardCycleView(_ view: StrictBedBoardCycleView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedDurationMinutes) + parsedMaximum
    }
}
