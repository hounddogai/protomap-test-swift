import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board allocation.
    final class BedBoardAllocationView {
        var code: String
        var label: String
        var segmentText: String
        var durationMinutesText: String
        var pinnedText: String
        var payer: String
        var diagnosisCode: String
        var archived: String
        var channel: String
        var reviewer: String
        var statusLabel: String

        init(code: String, label: String, segmentText: String, durationMinutesText: String, pinnedText: String, payer: String, diagnosisCode: String, archived: String, channel: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.segmentText = segmentText
            self.durationMinutesText = durationMinutesText
            self.pinnedText = pinnedText
            self.payer = payer
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.channel = channel
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardAllocationView(_ item: BedBoardAllocation) -> BedBoardAllocationView {
        return BedBoardAllocationView(
            code: item.code,
            label: item.label,
            segmentText: item.segment,
            durationMinutesText: String(item.durationMinutes),
            pinnedText: "\(item.pinned)",
            payer: Kit.Text.truncate(item.payer, limit: 64),
            diagnosisCode: item.diagnosisCode,
            archived: "\(item.archived)",
            channel: Kit.Text.truncate(item.channel, limit: 120),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardAllocationViews(_ items: [BedBoardAllocation]) -> [BedBoardAllocationView] {
        var views: [BedBoardAllocationView] = []
        for item in items {
            views.append(toBedBoardAllocationView(item))
        }
        return views
    }

    static func sumBedBoardAllocationView(_ view: BedBoardAllocationView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedDurationMinutes)
    }
}
