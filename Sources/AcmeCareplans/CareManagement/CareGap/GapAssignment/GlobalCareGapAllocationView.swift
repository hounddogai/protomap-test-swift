import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global care gap allocation.
    final class GlobalCareGapAllocationView {
        var code: String
        var titleText: String
        var margin: String
        var notesText: String
        var ownerID: String
        var channelText: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, titleText: String, margin: String, notesText: String, ownerID: String, channelText: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.margin = margin
            self.notesText = notesText
            self.ownerID = ownerID
            self.channelText = channelText
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCareGapAllocationView(_ item: GlobalCareGapAllocation) -> GlobalCareGapAllocationView {
        return GlobalCareGapAllocationView(
            code: item.code,
            titleText: item.title,
            margin: String(format: "%.2f", item.margin),
            notesText: item.notes,
            ownerID: item.ownerID,
            channelText: item.channel,
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCareGapAllocationViews(_ items: [GlobalCareGapAllocation]) -> [GlobalCareGapAllocationView] {
        var views: [GlobalCareGapAllocationView] = []
        for item in items {
            views.append(toGlobalCareGapAllocationView(item))
        }
        return views
    }

    static func sumGlobalCareGapAllocationView(_ view: GlobalCareGapAllocationView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedMargin + Double(parsedStartsAt)
    }
}
