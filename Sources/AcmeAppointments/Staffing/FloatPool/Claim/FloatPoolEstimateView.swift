import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool estimate.
    final class FloatPoolEstimateView {
        var code: String
        var name: String
        var archived: String
        var capacity: String
        var summaryText: String
        var revision: String
        var statusLabel: String

        init(code: String, name: String, archived: String, capacity: String, summaryText: String, revision: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archived = archived
            self.capacity = capacity
            self.summaryText = summaryText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolEstimateView(_ item: FloatPoolEstimate) -> FloatPoolEstimateView {
        return FloatPoolEstimateView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            archived: "\(item.archived)",
            capacity: String(item.capacity),
            summaryText: item.summary,
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolEstimateViews(_ items: [FloatPoolEstimate]) -> [FloatPoolEstimateView] {
        var views: [FloatPoolEstimateView] = []
        for item in items {
            views.append(toFloatPoolEstimateView(item))
        }
        return views
    }

    static func sumFloatPoolEstimateView(_ view: FloatPoolEstimateView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedCapacity) + Double(parsedRevision)
    }
}
