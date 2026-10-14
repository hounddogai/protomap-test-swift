import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board target.
    final class BedBoardTargetView {
        var code: String
        var label: String
        var acuityText: String
        var archived: String
        var active: String
        var facility: String
        var channelText: String
        var weightText: String
        var statusLabel: String

        init(code: String, label: String, acuityText: String, archived: String, active: String, facility: String, channelText: String, weightText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.acuityText = acuityText
            self.archived = archived
            self.active = active
            self.facility = facility
            self.channelText = channelText
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardTargetView(_ item: BedBoardTarget) -> BedBoardTargetView {
        return BedBoardTargetView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            acuityText: String(item.acuity),
            archived: "\(item.archived)",
            active: "\(item.active)",
            facility: item.facility,
            channelText: Kit.Text.truncate(item.channel, limit: 64),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardTargetViews(_ items: [BedBoardTarget]) -> [BedBoardTargetView] {
        var views: [BedBoardTargetView] = []
        for item in items {
            views.append(toBedBoardTargetView(item))
        }
        return views
    }

    static func sumBedBoardTargetView(_ view: BedBoardTargetView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedAcuity) + parsedWeight
    }
}
