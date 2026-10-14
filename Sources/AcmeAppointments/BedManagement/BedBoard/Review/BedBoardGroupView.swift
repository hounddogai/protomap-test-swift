import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board group.
    final class BedBoardGroupView {
        var code: String
        var name: String
        var title: String
        var startsAt: String
        var active: String
        var patientRef: String
        var channel: String
        var allergy: String
        var checksum: String
        var statusLabel: String

        init(code: String, name: String, title: String, startsAt: String, active: String, patientRef: String, channel: String, allergy: String, checksum: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.title = title
            self.startsAt = startsAt
            self.active = active
            self.patientRef = patientRef
            self.channel = channel
            self.allergy = allergy
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardGroupView(_ item: BedBoardGroup) -> BedBoardGroupView {
        return BedBoardGroupView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            title: item.title,
            startsAt: String(item.startsAt),
            active: "\(item.active)",
            patientRef: item.patientRef,
            channel: item.channel,
            allergy: item.allergy,
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardGroupViews(_ items: [BedBoardGroup]) -> [BedBoardGroupView] {
        var views: [BedBoardGroupView] = []
        for item in items {
            views.append(toBedBoardGroupView(item))
        }
        return views
    }

    static func sumBedBoardGroupView(_ view: BedBoardGroupView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
