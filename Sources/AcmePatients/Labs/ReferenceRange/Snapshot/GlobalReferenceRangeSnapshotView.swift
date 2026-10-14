import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a global reference range snapshot.
    final class GlobalReferenceRangeSnapshotView {
        var codeText: String
        var label: String
        var capacity: String
        var checksum: String
        var rate: String
        var copayText: String
        var windowDaysText: String
        var clinicianID: String
        var statusLabel: String

        init(codeText: String, label: String, capacity: String, checksum: String, rate: String, copayText: String, windowDaysText: String, clinicianID: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.capacity = capacity
            self.checksum = checksum
            self.rate = rate
            self.copayText = copayText
            self.windowDaysText = windowDaysText
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalReferenceRangeSnapshotView(_ item: GlobalReferenceRangeSnapshot) -> GlobalReferenceRangeSnapshotView {
        return GlobalReferenceRangeSnapshotView(
            codeText: item.code,
            label: item.label,
            capacity: String(item.capacity),
            checksum: item.checksum,
            rate: String(format: "%.2f", item.rate),
            copayText: String(format: "%.2f", item.copay),
            windowDaysText: String(item.windowDays),
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalReferenceRangeSnapshotViews(_ items: [GlobalReferenceRangeSnapshot]) -> [GlobalReferenceRangeSnapshotView] {
        var views: [GlobalReferenceRangeSnapshotView] = []
        for item in items {
            views.append(toGlobalReferenceRangeSnapshotView(item))
        }
        return views
    }

    static func sumGlobalReferenceRangeSnapshotView(_ view: GlobalReferenceRangeSnapshotView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedCapacity) + parsedRate + parsedCopay
    }
}
