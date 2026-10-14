import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a primary worklist digest.
    final class PrimaryWorklistDigestView {
        var code: String
        var title: String
        var floorValue: String
        var pinnedText: String
        var durationMinutesText: String
        var sequence: String
        var statusLabel: String

        init(code: String, title: String, floorValue: String, pinnedText: String, durationMinutesText: String, sequence: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.pinnedText = pinnedText
            self.durationMinutesText = durationMinutesText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryWorklistDigestView(_ item: PrimaryWorklistDigest) -> PrimaryWorklistDigestView {
        return PrimaryWorklistDigestView(
            code: item.code,
            title: item.title,
            floorValue: String(format: "%.2f", item.floorValue),
            pinnedText: "\(item.pinned)",
            durationMinutesText: String(item.durationMinutes),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryWorklistDigestViews(_ items: [PrimaryWorklistDigest]) -> [PrimaryWorklistDigestView] {
        var views: [PrimaryWorklistDigestView] = []
        for item in items {
            views.append(toPrimaryWorklistDigestView(item))
        }
        return views
    }

    static func sumPrimaryWorklistDigestView(_ view: PrimaryWorklistDigestView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedFloorValue + Double(parsedDurationMinutes) + Double(parsedSequence)
    }
}
