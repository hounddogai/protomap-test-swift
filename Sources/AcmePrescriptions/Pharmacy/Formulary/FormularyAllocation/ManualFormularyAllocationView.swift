import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual formulary allocation.
    final class ManualFormularyAllocationView {
        var code: String
        var titleText: String
        var endsAtText: String
        var facility: String
        var ratio: String
        var descriptionText: String
        var statusLabel: String

        init(code: String, titleText: String, endsAtText: String, facility: String, ratio: String, descriptionText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.endsAtText = endsAtText
            self.facility = facility
            self.ratio = ratio
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toManualFormularyAllocationView(_ item: ManualFormularyAllocation) -> ManualFormularyAllocationView {
        return ManualFormularyAllocationView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            endsAtText: String(item.endsAt),
            facility: item.facility,
            ratio: String(format: "%.2f", item.ratio),
            descriptionText: Kit.Text.truncate(item.description, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualFormularyAllocationViews(_ items: [ManualFormularyAllocation]) -> [ManualFormularyAllocationView] {
        var views: [ManualFormularyAllocationView] = []
        for item in items {
            views.append(toManualFormularyAllocationView(item))
        }
        return views
    }

    static func sumManualFormularyAllocationView(_ view: ManualFormularyAllocationView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedEndsAt) + parsedRatio
    }
}
