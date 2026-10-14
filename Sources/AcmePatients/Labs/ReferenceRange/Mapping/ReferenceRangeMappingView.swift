import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range mapping.
    final class ReferenceRangeMappingView {
        var codeText: String
        var name: String
        var visitMinutes: String
        var ratio: String
        var retries: String
        var statusLabel: String

        init(codeText: String, name: String, visitMinutes: String, ratio: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.visitMinutes = visitMinutes
            self.ratio = ratio
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeMappingView(_ item: ReferenceRangeMapping) -> ReferenceRangeMappingView {
        return ReferenceRangeMappingView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            visitMinutes: String(item.visitMinutes),
            ratio: String(format: "%.2f", item.ratio),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeMappingViews(_ items: [ReferenceRangeMapping]) -> [ReferenceRangeMappingView] {
        var views: [ReferenceRangeMappingView] = []
        for item in items {
            views.append(toReferenceRangeMappingView(item))
        }
        return views
    }

    static func sumReferenceRangeMappingView(_ view: ReferenceRangeMappingView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedVisitMinutes) + parsedRatio + Double(parsedRetries)
    }
}
