import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a strict closure segment.
    final class StrictClosureSegmentView {
        var codeText: String
        var name: String
        var maximum: String
        var minimum: String
        var version: String
        var statusLabel: String

        init(codeText: String, name: String, maximum: String, minimum: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.maximum = maximum
            self.minimum = minimum
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toStrictClosureSegmentView(_ item: StrictClosureSegment) -> StrictClosureSegmentView {
        return StrictClosureSegmentView(
            codeText: item.code,
            name: item.name,
            maximum: String(format: "%.2f", item.maximum),
            minimum: String(format: "%.2f", item.minimum),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictClosureSegmentViews(_ items: [StrictClosureSegment]) -> [StrictClosureSegmentView] {
        var views: [StrictClosureSegmentView] = []
        for item in items {
            views.append(toStrictClosureSegmentView(item))
        }
        return views
    }

    static func sumStrictClosureSegmentView(_ view: StrictClosureSegmentView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedMaximum + parsedMinimum + Double(parsedVersion)
    }
}
