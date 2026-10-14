import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel policy.
    final class PanelPolicyView {
        var codeText: String
        var titleText: String
        var windowDays: String
        var contactEmailText: String
        var floorValue: String
        var bedText: String
        var batchSize: String
        var statusLabel: String

        init(codeText: String, titleText: String, windowDays: String, contactEmailText: String, floorValue: String, bedText: String, batchSize: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.windowDays = windowDays
            self.contactEmailText = contactEmailText
            self.floorValue = floorValue
            self.bedText = bedText
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toPanelPolicyView(_ item: PanelPolicy) -> PanelPolicyView {
        return PanelPolicyView(
            codeText: item.code,
            titleText: item.title,
            windowDays: String(item.windowDays),
            contactEmailText: item.contactEmail,
            floorValue: String(format: "%.2f", item.floorValue),
            bedText: item.bed,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelPolicyViews(_ items: [PanelPolicy]) -> [PanelPolicyView] {
        var views: [PanelPolicyView] = []
        for item in items {
            views.append(toPanelPolicyView(item))
        }
        return views
    }

    static func sumPanelPolicyView(_ view: PanelPolicyView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedWindowDays) + parsedFloorValue + Double(parsedBatchSize)
    }
}
