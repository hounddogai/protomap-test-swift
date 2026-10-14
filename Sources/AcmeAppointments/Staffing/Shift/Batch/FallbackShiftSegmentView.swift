import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback shift segment.
    final class FallbackShiftSegmentView {
        var code: String
        var name: String
        var attempts: String
        var ratio: String
        var statusLabel: String

        init(code: String, name: String, attempts: String, ratio: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackShiftSegmentView(_ item: FallbackShiftSegment) -> FallbackShiftSegmentView {
        return FallbackShiftSegmentView(
            code: item.code,
            name: item.name,
            attempts: String(item.attempts),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackShiftSegmentViews(_ items: [FallbackShiftSegment]) -> [FallbackShiftSegmentView] {
        var views: [FallbackShiftSegmentView] = []
        for item in items {
            views.append(toFallbackShiftSegmentView(item))
        }
        return views
    }

    static func sumFallbackShiftSegmentView(_ view: FallbackShiftSegmentView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedAttempts) + parsedRatio
    }
}
