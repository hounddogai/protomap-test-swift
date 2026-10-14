import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a pending overtime snapshot.
    final class PendingOvertimeSnapshotView {
        var codeText: String
        var titleText: String
        var threshold: String
        var dosageMg: String
        var cost: String
        var statusLabel: String

        init(codeText: String, titleText: String, threshold: String, dosageMg: String, cost: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.threshold = threshold
            self.dosageMg = dosageMg
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toPendingOvertimeSnapshotView(_ item: PendingOvertimeSnapshot) -> PendingOvertimeSnapshotView {
        return PendingOvertimeSnapshotView(
            codeText: item.code,
            titleText: item.title,
            threshold: String(format: "%.2f", item.threshold),
            dosageMg: String(format: "%.2f", item.dosageMg),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingOvertimeSnapshotViews(_ items: [PendingOvertimeSnapshot]) -> [PendingOvertimeSnapshotView] {
        var views: [PendingOvertimeSnapshotView] = []
        for item in items {
            views.append(toPendingOvertimeSnapshotView(item))
        }
        return views
    }

    static func sumPendingOvertimeSnapshotView(_ view: PendingOvertimeSnapshotView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedThreshold + parsedDosageMg + parsedCost
    }
}
