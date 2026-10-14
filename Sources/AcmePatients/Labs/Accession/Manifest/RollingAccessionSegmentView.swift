import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling accession segment.
    final class RollingAccessionSegmentView {
        var code: String
        var label: String
        var copay: String
        var retriesText: String
        var archived: String
        var wardText: String
        var statusLabel: String

        init(code: String, label: String, copay: String, retriesText: String, archived: String, wardText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.copay = copay
            self.retriesText = retriesText
            self.archived = archived
            self.wardText = wardText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAccessionSegmentView(_ item: RollingAccessionSegment) -> RollingAccessionSegmentView {
        return RollingAccessionSegmentView(
            code: item.code,
            label: item.label,
            copay: String(format: "%.2f", item.copay),
            retriesText: String(item.retries),
            archived: "\(item.archived)",
            wardText: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAccessionSegmentViews(_ items: [RollingAccessionSegment]) -> [RollingAccessionSegmentView] {
        var views: [RollingAccessionSegmentView] = []
        for item in items {
            views.append(toRollingAccessionSegmentView(item))
        }
        return views
    }

    static func sumRollingAccessionSegmentView(_ view: RollingAccessionSegmentView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedCopay + Double(parsedRetries)
    }
}
