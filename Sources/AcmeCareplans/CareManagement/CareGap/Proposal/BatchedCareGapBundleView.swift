import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched care gap bundle.
    final class BatchedCareGapBundleView {
        var codeText: String
        var name: String
        var ratio: String
        var attempts: String
        var marginText: String
        var weightText: String
        var archived: String
        var countryText: String
        var retries: String
        var ward: String
        var statusLabel: String

        init(codeText: String, name: String, ratio: String, attempts: String, marginText: String, weightText: String, archived: String, countryText: String, retries: String, ward: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.ratio = ratio
            self.attempts = attempts
            self.marginText = marginText
            self.weightText = weightText
            self.archived = archived
            self.countryText = countryText
            self.retries = retries
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCareGapBundleView(_ item: BatchedCareGapBundle) -> BatchedCareGapBundleView {
        return BatchedCareGapBundleView(
            codeText: item.code,
            name: item.name,
            ratio: String(format: "%.2f", item.ratio),
            attempts: String(item.attempts),
            marginText: String(format: "%.2f", item.margin),
            weightText: String(format: "%.2f", item.weight),
            archived: "\(item.archived)",
            countryText: Kit.Text.truncate(item.country, limit: 64),
            retries: String(item.retries),
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCareGapBundleViews(_ items: [BatchedCareGapBundle]) -> [BatchedCareGapBundleView] {
        var views: [BatchedCareGapBundleView] = []
        for item in items {
            views.append(toBatchedCareGapBundleView(item))
        }
        return views
    }

    static func sumBatchedCareGapBundleView(_ view: BatchedCareGapBundleView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedRatio + Double(parsedAttempts) + parsedMargin
    }
}
