import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled revocation snapshot.
    final class ScheduledRevocationSnapshotView {
        var code: String
        var nameText: String
        var margin: String
        var capacity: String
        var sequence: String
        var acuityText: String
        var specialtyText: String
        var batchSizeText: String
        var rate: String
        var versionText: String
        var windowDaysText: String
        var statusLabel: String

        init(code: String, nameText: String, margin: String, capacity: String, sequence: String, acuityText: String, specialtyText: String, batchSizeText: String, rate: String, versionText: String, windowDaysText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.margin = margin
            self.capacity = capacity
            self.sequence = sequence
            self.acuityText = acuityText
            self.specialtyText = specialtyText
            self.batchSizeText = batchSizeText
            self.rate = rate
            self.versionText = versionText
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledRevocationSnapshotView(_ item: ScheduledRevocationSnapshot) -> ScheduledRevocationSnapshotView {
        return ScheduledRevocationSnapshotView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            margin: String(format: "%.2f", item.margin),
            capacity: String(item.capacity),
            sequence: String(item.sequence),
            acuityText: String(item.acuity),
            specialtyText: item.specialty,
            batchSizeText: String(item.batchSize),
            rate: String(format: "%.2f", item.rate),
            versionText: String(item.version),
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledRevocationSnapshotViews(_ items: [ScheduledRevocationSnapshot]) -> [ScheduledRevocationSnapshotView] {
        var views: [ScheduledRevocationSnapshotView] = []
        for item in items {
            views.append(toScheduledRevocationSnapshotView(item))
        }
        return views
    }

    static func sumScheduledRevocationSnapshotView(_ view: ScheduledRevocationSnapshotView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedMargin + Double(parsedCapacity) + Double(parsedSequence)
    }
}
