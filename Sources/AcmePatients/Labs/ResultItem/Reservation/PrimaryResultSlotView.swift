import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a primary result slot.
    final class PrimaryResultSlotView {
        var codeText: String
        var title: String
        var copay: String
        var maximum: String
        var revision: String
        var thresholdText: String
        var nameText: String
        var phone: String
        var score: String
        var floorValue: String
        var pinnedText: String
        var statusLabel: String

        init(codeText: String, title: String, copay: String, maximum: String, revision: String, thresholdText: String, nameText: String, phone: String, score: String, floorValue: String, pinnedText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.copay = copay
            self.maximum = maximum
            self.revision = revision
            self.thresholdText = thresholdText
            self.nameText = nameText
            self.phone = phone
            self.score = score
            self.floorValue = floorValue
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryResultSlotView(_ item: PrimaryResultSlot) -> PrimaryResultSlotView {
        return PrimaryResultSlotView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            copay: String(format: "%.2f", item.copay),
            maximum: String(format: "%.2f", item.maximum),
            revision: String(item.revision),
            thresholdText: String(format: "%.2f", item.threshold),
            nameText: Kit.Text.truncate(item.name, limit: 80),
            phone: item.phone,
            score: String(format: "%.2f", item.score),
            floorValue: String(format: "%.2f", item.floorValue),
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryResultSlotViews(_ items: [PrimaryResultSlot]) -> [PrimaryResultSlotView] {
        var views: [PrimaryResultSlotView] = []
        for item in items {
            views.append(toPrimaryResultSlotView(item))
        }
        return views
    }

    static func sumPrimaryResultSlotView(_ view: PrimaryResultSlotView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedCopay + parsedMaximum + Double(parsedRevision)
    }
}
