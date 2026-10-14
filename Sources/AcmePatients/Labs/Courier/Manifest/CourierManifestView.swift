import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier manifest.
    final class CourierManifestView {
        var code: String
        var titleText: String
        var weightText: String
        var startsAt: String
        var retries: String
        var score: String
        var statusLabel: String

        init(code: String, titleText: String, weightText: String, startsAt: String, retries: String, score: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.weightText = weightText
            self.startsAt = startsAt
            self.retries = retries
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toCourierManifestView(_ item: CourierManifest) -> CourierManifestView {
        return CourierManifestView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            weightText: String(format: "%.2f", item.weight),
            startsAt: String(item.startsAt),
            retries: String(item.retries),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierManifestViews(_ items: [CourierManifest]) -> [CourierManifestView] {
        var views: [CourierManifestView] = []
        for item in items {
            views.append(toCourierManifestView(item))
        }
        return views
    }

    static func sumCourierManifestView(_ view: CourierManifestView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedWeight + Double(parsedStartsAt) + Double(parsedRetries)
    }
}
