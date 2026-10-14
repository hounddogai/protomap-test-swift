import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global order set estimate.
    final class GlobalOrderSetEstimateView {
        var codeText: String
        var titleText: String
        var priority: String
        var archived: String
        var discount: String
        var version: String
        var dosageMgText: String
        var statusLabel: String

        init(codeText: String, titleText: String, priority: String, archived: String, discount: String, version: String, dosageMgText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.priority = priority
            self.archived = archived
            self.discount = discount
            self.version = version
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalOrderSetEstimateView(_ item: GlobalOrderSetEstimate) -> GlobalOrderSetEstimateView {
        return GlobalOrderSetEstimateView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            priority: String(item.priority),
            archived: "\(item.archived)",
            discount: String(format: "%.2f", item.discount),
            version: String(item.version),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalOrderSetEstimateViews(_ items: [GlobalOrderSetEstimate]) -> [GlobalOrderSetEstimateView] {
        var views: [GlobalOrderSetEstimateView] = []
        for item in items {
            views.append(toGlobalOrderSetEstimateView(item))
        }
        return views
    }

    static func sumGlobalOrderSetEstimateView(_ view: GlobalOrderSetEstimateView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedPriority) + parsedDiscount + Double(parsedVersion)
    }
}
