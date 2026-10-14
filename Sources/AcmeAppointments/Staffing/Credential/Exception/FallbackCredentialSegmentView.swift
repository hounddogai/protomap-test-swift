import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback credential segment.
    final class FallbackCredentialSegmentView {
        var code: String
        var title: String
        var clinicianID: String
        var specialty: String
        var graceDays: String
        var capacity: String
        var threshold: String
        var statusLabel: String

        init(code: String, title: String, clinicianID: String, specialty: String, graceDays: String, capacity: String, threshold: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.graceDays = graceDays
            self.capacity = capacity
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCredentialSegmentView(_ item: FallbackCredentialSegment) -> FallbackCredentialSegmentView {
        return FallbackCredentialSegmentView(
            code: item.code,
            title: item.title,
            clinicianID: item.clinicianID,
            specialty: item.specialty,
            graceDays: String(item.graceDays),
            capacity: String(item.capacity),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCredentialSegmentViews(_ items: [FallbackCredentialSegment]) -> [FallbackCredentialSegmentView] {
        var views: [FallbackCredentialSegmentView] = []
        for item in items {
            views.append(toFallbackCredentialSegmentView(item))
        }
        return views
    }

    static func sumFallbackCredentialSegmentView(_ view: FallbackCredentialSegmentView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedCapacity) + parsedThreshold
    }
}
