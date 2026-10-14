import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a capped shift snapshot.
    final class CappedShiftSnapshotView {
        var code: String
        var labelText: String
        var floorValue: String
        var source: String
        var revision: String
        var currencyText: String
        var summary: String
        var retries: String
        var statusLabel: String

        init(code: String, labelText: String, floorValue: String, source: String, revision: String, currencyText: String, summary: String, retries: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.floorValue = floorValue
            self.source = source
            self.revision = revision
            self.currencyText = currencyText
            self.summary = summary
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toCappedShiftSnapshotView(_ item: CappedShiftSnapshot) -> CappedShiftSnapshotView {
        return CappedShiftSnapshotView(
            code: item.code,
            labelText: item.label,
            floorValue: String(format: "%.2f", item.floorValue),
            source: item.source,
            revision: String(item.revision),
            currencyText: Kit.Text.truncate(item.currency, limit: 120),
            summary: item.summary,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedShiftSnapshotViews(_ items: [CappedShiftSnapshot]) -> [CappedShiftSnapshotView] {
        var views: [CappedShiftSnapshotView] = []
        for item in items {
            views.append(toCappedShiftSnapshotView(item))
        }
        return views
    }

    static func sumCappedShiftSnapshotView(_ view: CappedShiftSnapshotView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedFloorValue + Double(parsedRevision) + Double(parsedRetries)
    }
}
