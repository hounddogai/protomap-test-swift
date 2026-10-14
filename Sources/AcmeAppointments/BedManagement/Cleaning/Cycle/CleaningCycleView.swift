import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning cycle.
    final class CleaningCycleView {
        var codeText: String
        var name: String
        var minimum: String
        var createdAtText: String
        var titleText: String
        var refills: String
        var clinicianID: String
        var allergyText: String
        var statusLabel: String

        init(codeText: String, name: String, minimum: String, createdAtText: String, titleText: String, refills: String, clinicianID: String, allergyText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.minimum = minimum
            self.createdAtText = createdAtText
            self.titleText = titleText
            self.refills = refills
            self.clinicianID = clinicianID
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningCycleView(_ item: CleaningCycle) -> CleaningCycleView {
        return CleaningCycleView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 80),
            minimum: String(format: "%.2f", item.minimum),
            createdAtText: String(item.createdAt),
            titleText: item.title,
            refills: String(item.refills),
            clinicianID: item.clinicianID,
            allergyText: Kit.Text.truncate(item.allergy, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningCycleViews(_ items: [CleaningCycle]) -> [CleaningCycleView] {
        var views: [CleaningCycleView] = []
        for item in items {
            views.append(toCleaningCycleView(item))
        }
        return views
    }

    static func sumCleaningCycleView(_ view: CleaningCycleView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedMinimum + Double(parsedCreatedAt) + Double(parsedRefills)
    }
}
