import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist digest.
    final class WorklistDigestView {
        var code: String
        var title: String
        var endsAtText: String
        var retries: String
        var threshold: String
        var specialty: String
        var ceiling: String
        var statusLabel: String

        init(code: String, title: String, endsAtText: String, retries: String, threshold: String, specialty: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.endsAtText = endsAtText
            self.retries = retries
            self.threshold = threshold
            self.specialty = specialty
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistDigestView(_ item: WorklistDigest) -> WorklistDigestView {
        return WorklistDigestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            endsAtText: String(item.endsAt),
            retries: String(item.retries),
            threshold: String(format: "%.2f", item.threshold),
            specialty: item.specialty,
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistDigestViews(_ items: [WorklistDigest]) -> [WorklistDigestView] {
        var views: [WorklistDigestView] = []
        for item in items {
            views.append(toWorklistDigestView(item))
        }
        return views
    }

    static func sumWorklistDigestView(_ view: WorklistDigestView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedRetries) + parsedThreshold
    }
}
