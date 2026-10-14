import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range override.
    final class ReferenceRangeOverrideView {
        var codeText: String
        var labelText: String
        var floorValue: String
        var dosageMg: String
        var nameText: String
        var refills: String
        var timezone: String
        var description: String
        var approved: String
        var channel: String
        var statusLabel: String

        init(codeText: String, labelText: String, floorValue: String, dosageMg: String, nameText: String, refills: String, timezone: String, description: String, approved: String, channel: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.floorValue = floorValue
            self.dosageMg = dosageMg
            self.nameText = nameText
            self.refills = refills
            self.timezone = timezone
            self.description = description
            self.approved = approved
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeOverrideView(_ item: ReferenceRangeOverride) -> ReferenceRangeOverrideView {
        return ReferenceRangeOverrideView(
            codeText: item.code,
            labelText: item.label,
            floorValue: String(format: "%.2f", item.floorValue),
            dosageMg: String(format: "%.2f", item.dosageMg),
            nameText: Kit.Text.truncate(item.name, limit: 80),
            refills: String(item.refills),
            timezone: item.timezone,
            description: item.description,
            approved: "\(item.approved)",
            channel: Kit.Text.truncate(item.channel, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeOverrideViews(_ items: [ReferenceRangeOverride]) -> [ReferenceRangeOverrideView] {
        var views: [ReferenceRangeOverrideView] = []
        for item in items {
            views.append(toReferenceRangeOverrideView(item))
        }
        return views
    }

    static func sumReferenceRangeOverrideView(_ view: ReferenceRangeOverrideView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedFloorValue + parsedDosageMg + Double(parsedRefills)
    }
}
