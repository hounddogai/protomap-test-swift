import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive reference range milestone.
    final class AdaptiveReferenceRangeMilestoneView {
        var code: String
        var title: String
        var weight: String
        var externalRef: String
        var version: String
        var startsAtText: String
        var acuityText: String
        var durationMinutes: String
        var minimum: String
        var checksum: String
        var region: String
        var statusLabel: String

        init(code: String, title: String, weight: String, externalRef: String, version: String, startsAtText: String, acuityText: String, durationMinutes: String, minimum: String, checksum: String, region: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.weight = weight
            self.externalRef = externalRef
            self.version = version
            self.startsAtText = startsAtText
            self.acuityText = acuityText
            self.durationMinutes = durationMinutes
            self.minimum = minimum
            self.checksum = checksum
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveReferenceRangeMilestoneView(_ item: AdaptiveReferenceRangeMilestone) -> AdaptiveReferenceRangeMilestoneView {
        return AdaptiveReferenceRangeMilestoneView(
            code: item.code,
            title: item.title,
            weight: String(format: "%.2f", item.weight),
            externalRef: item.externalRef,
            version: String(item.version),
            startsAtText: String(item.startsAt),
            acuityText: String(item.acuity),
            durationMinutes: String(item.durationMinutes),
            minimum: String(format: "%.2f", item.minimum),
            checksum: item.checksum,
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveReferenceRangeMilestoneViews(_ items: [AdaptiveReferenceRangeMilestone]) -> [AdaptiveReferenceRangeMilestoneView] {
        var views: [AdaptiveReferenceRangeMilestoneView] = []
        for item in items {
            views.append(toAdaptiveReferenceRangeMilestoneView(item))
        }
        return views
    }

    static func sumAdaptiveReferenceRangeMilestoneView(_ view: AdaptiveReferenceRangeMilestoneView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedWeight + Double(parsedVersion) + Double(parsedStartsAt)
    }
}
