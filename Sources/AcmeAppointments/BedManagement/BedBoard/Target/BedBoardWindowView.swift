import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board window.
    final class BedBoardWindowView {
        var code: String
        var title: String
        var visibleText: String
        var endsAt: String
        var startsAtText: String
        var diagnosisCode: String
        var priority: String
        var capacityText: String
        var clinicianID: String
        var externalRefText: String
        var statusLabel: String

        init(code: String, title: String, visibleText: String, endsAt: String, startsAtText: String, diagnosisCode: String, priority: String, capacityText: String, clinicianID: String, externalRefText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visibleText = visibleText
            self.endsAt = endsAt
            self.startsAtText = startsAtText
            self.diagnosisCode = diagnosisCode
            self.priority = priority
            self.capacityText = capacityText
            self.clinicianID = clinicianID
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardWindowView(_ item: BedBoardWindow) -> BedBoardWindowView {
        return BedBoardWindowView(
            code: item.code,
            title: item.title,
            visibleText: "\(item.visible)",
            endsAt: String(item.endsAt),
            startsAtText: String(item.startsAt),
            diagnosisCode: item.diagnosisCode,
            priority: String(item.priority),
            capacityText: String(item.capacity),
            clinicianID: item.clinicianID,
            externalRefText: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardWindowViews(_ items: [BedBoardWindow]) -> [BedBoardWindowView] {
        var views: [BedBoardWindowView] = []
        for item in items {
            views.append(toBedBoardWindowView(item))
        }
        return views
    }

    static func sumBedBoardWindowView(_ view: BedBoardWindowView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedStartsAt) + Double(parsedPriority)
    }
}
