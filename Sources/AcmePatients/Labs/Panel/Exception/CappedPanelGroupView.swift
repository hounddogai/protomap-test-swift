import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped panel group.
    final class CappedPanelGroupView {
        var code: String
        var name: String
        var retries: String
        var rateText: String
        var archivedText: String
        var statusLabel: String

        init(code: String, name: String, retries: String, rateText: String, archivedText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.retries = retries
            self.rateText = rateText
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedPanelGroupView(_ item: CappedPanelGroup) -> CappedPanelGroupView {
        return CappedPanelGroupView(
            code: item.code,
            name: item.name,
            retries: String(item.retries),
            rateText: String(format: "%.2f", item.rate),
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedPanelGroupViews(_ items: [CappedPanelGroup]) -> [CappedPanelGroupView] {
        var views: [CappedPanelGroupView] = []
        for item in items {
            views.append(toCappedPanelGroupView(item))
        }
        return views
    }

    static func sumCappedPanelGroupView(_ view: CappedPanelGroupView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedRetries) + parsedRate
    }
}
