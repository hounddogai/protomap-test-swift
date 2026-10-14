import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board checkpoint.
    final class BedBoardCheckpointView {
        var code: String
        var titleText: String
        var pinnedText: String
        var segmentText: String
        var specialty: String
        var quantity: String
        var statusLabel: String

        init(code: String, titleText: String, pinnedText: String, segmentText: String, specialty: String, quantity: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.pinnedText = pinnedText
            self.segmentText = segmentText
            self.specialty = specialty
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardCheckpointView(_ item: BedBoardCheckpoint) -> BedBoardCheckpointView {
        return BedBoardCheckpointView(
            code: item.code,
            titleText: item.title,
            pinnedText: "\(item.pinned)",
            segmentText: item.segment,
            specialty: item.specialty,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardCheckpointViews(_ items: [BedBoardCheckpoint]) -> [BedBoardCheckpointView] {
        var views: [BedBoardCheckpointView] = []
        for item in items {
            views.append(toBedBoardCheckpointView(item))
        }
        return views
    }

    static func sumBedBoardCheckpointView(_ view: BedBoardCheckpointView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
