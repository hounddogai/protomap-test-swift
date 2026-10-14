import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped closure segment.
    final class CappedClosureSegmentView {
        var codeText: String
        var nameText: String
        var currency: String
        var minimum: String
        var copay: String
        var pinned: String
        var diagnosisCode: String
        var versionText: String
        var startsAt: String
        var capacity: String
        var facility: String
        var statusLabel: String

        init(codeText: String, nameText: String, currency: String, minimum: String, copay: String, pinned: String, diagnosisCode: String, versionText: String, startsAt: String, capacity: String, facility: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.currency = currency
            self.minimum = minimum
            self.copay = copay
            self.pinned = pinned
            self.diagnosisCode = diagnosisCode
            self.versionText = versionText
            self.startsAt = startsAt
            self.capacity = capacity
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toCappedClosureSegmentView(_ item: CappedClosureSegment) -> CappedClosureSegmentView {
        return CappedClosureSegmentView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            currency: item.currency,
            minimum: String(format: "%.2f", item.minimum),
            copay: String(format: "%.2f", item.copay),
            pinned: "\(item.pinned)",
            diagnosisCode: item.diagnosisCode,
            versionText: String(item.version),
            startsAt: String(item.startsAt),
            capacity: String(item.capacity),
            facility: Kit.Text.truncate(item.facility, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedClosureSegmentViews(_ items: [CappedClosureSegment]) -> [CappedClosureSegmentView] {
        var views: [CappedClosureSegmentView] = []
        for item in items {
            views.append(toCappedClosureSegmentView(item))
        }
        return views
    }

    static func sumCappedClosureSegmentView(_ view: CappedClosureSegmentView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedMinimum + parsedCopay + Double(parsedVersion)
    }
}
