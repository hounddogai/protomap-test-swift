import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive disclosure exception.
    final class AdaptiveDisclosureExceptionView {
        var codeText: String
        var name: String
        var specialty: String
        var startsAt: String
        var payerText: String
        var checksum: String
        var locale: String
        var versionText: String
        var batchSize: String
        var threshold: String
        var reviewerText: String
        var statusLabel: String

        init(codeText: String, name: String, specialty: String, startsAt: String, payerText: String, checksum: String, locale: String, versionText: String, batchSize: String, threshold: String, reviewerText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.specialty = specialty
            self.startsAt = startsAt
            self.payerText = payerText
            self.checksum = checksum
            self.locale = locale
            self.versionText = versionText
            self.batchSize = batchSize
            self.threshold = threshold
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveDisclosureExceptionView(_ item: AdaptiveDisclosureException) -> AdaptiveDisclosureExceptionView {
        return AdaptiveDisclosureExceptionView(
            codeText: item.code,
            name: item.name,
            specialty: item.specialty,
            startsAt: String(item.startsAt),
            payerText: item.payer,
            checksum: item.checksum,
            locale: item.locale,
            versionText: String(item.version),
            batchSize: String(item.batchSize),
            threshold: String(format: "%.2f", item.threshold),
            reviewerText: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveDisclosureExceptionViews(_ items: [AdaptiveDisclosureException]) -> [AdaptiveDisclosureExceptionView] {
        var views: [AdaptiveDisclosureExceptionView] = []
        for item in items {
            views.append(toAdaptiveDisclosureExceptionView(item))
        }
        return views
    }

    static func sumAdaptiveDisclosureExceptionView(_ view: AdaptiveDisclosureExceptionView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedVersion) + Double(parsedBatchSize)
    }
}
