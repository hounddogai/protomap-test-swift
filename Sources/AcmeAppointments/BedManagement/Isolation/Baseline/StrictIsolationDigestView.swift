import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict isolation digest.
    final class StrictIsolationDigestView {
        var code: String
        var title: String
        var attempts: String
        var threshold: String
        var clinicianID: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, title: String, attempts: String, threshold: String, clinicianID: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.threshold = threshold
            self.clinicianID = clinicianID
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictIsolationDigestView(_ item: StrictIsolationDigest) -> StrictIsolationDigestView {
        return StrictIsolationDigestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            attempts: String(item.attempts),
            threshold: String(format: "%.2f", item.threshold),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictIsolationDigestViews(_ items: [StrictIsolationDigest]) -> [StrictIsolationDigestView] {
        var views: [StrictIsolationDigestView] = []
        for item in items {
            views.append(toStrictIsolationDigestView(item))
        }
        return views
    }

    static func sumStrictIsolationDigestView(_ view: StrictIsolationDigestView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedAttempts) + parsedThreshold + parsedFloorValue
    }
}
