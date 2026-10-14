import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a capped statement snapshot.
    final class CappedStatementSnapshotView {
        var code: String
        var titleText: String
        var countryText: String
        var version: String
        var patientRef: String
        var timezone: String
        var statusLabel: String

        init(code: String, titleText: String, countryText: String, version: String, patientRef: String, timezone: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.countryText = countryText
            self.version = version
            self.patientRef = patientRef
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toCappedStatementSnapshotView(_ item: CappedStatementSnapshot) -> CappedStatementSnapshotView {
        return CappedStatementSnapshotView(
            code: item.code,
            titleText: item.title,
            countryText: item.country,
            version: String(item.version),
            patientRef: item.patientRef,
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedStatementSnapshotViews(_ items: [CappedStatementSnapshot]) -> [CappedStatementSnapshotView] {
        var views: [CappedStatementSnapshotView] = []
        for item in items {
            views.append(toCappedStatementSnapshotView(item))
        }
        return views
    }

    static func sumCappedStatementSnapshotView(_ view: CappedStatementSnapshotView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
