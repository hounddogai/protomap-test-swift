import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive specimen snapshot.
    final class AdaptiveSpecimenSnapshotView {
        var code: String
        var titleText: String
        var ward: String
        var durationMinutesText: String
        var unitText: String
        var statusLabel: String

        init(code: String, titleText: String, ward: String, durationMinutesText: String, unitText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ward = ward
            self.durationMinutesText = durationMinutesText
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveSpecimenSnapshotView(_ item: AdaptiveSpecimenSnapshot) -> AdaptiveSpecimenSnapshotView {
        return AdaptiveSpecimenSnapshotView(
            code: item.code,
            titleText: item.title,
            ward: item.ward,
            durationMinutesText: String(item.durationMinutes),
            unitText: Kit.Text.truncate(item.unit, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveSpecimenSnapshotViews(_ items: [AdaptiveSpecimenSnapshot]) -> [AdaptiveSpecimenSnapshotView] {
        var views: [AdaptiveSpecimenSnapshotView] = []
        for item in items {
            views.append(toAdaptiveSpecimenSnapshotView(item))
        }
        return views
    }

    static func sumAdaptiveSpecimenSnapshotView(_ view: AdaptiveSpecimenSnapshotView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedDurationMinutes)
    }
}
