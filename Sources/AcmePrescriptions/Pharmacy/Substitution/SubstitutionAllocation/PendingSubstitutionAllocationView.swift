import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending substitution allocation.
    final class PendingSubstitutionAllocationView {
        var code: String
        var titleText: String
        var active: String
        var version: String
        var approvedText: String
        var windowDays: String
        var amount: String
        var refills: String
        var capacity: String
        var copay: String
        var statusLabel: String

        init(code: String, titleText: String, active: String, version: String, approvedText: String, windowDays: String, amount: String, refills: String, capacity: String, copay: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.active = active
            self.version = version
            self.approvedText = approvedText
            self.windowDays = windowDays
            self.amount = amount
            self.refills = refills
            self.capacity = capacity
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toPendingSubstitutionAllocationView(_ item: PendingSubstitutionAllocation) -> PendingSubstitutionAllocationView {
        return PendingSubstitutionAllocationView(
            code: item.code,
            titleText: item.title,
            active: "\(item.active)",
            version: String(item.version),
            approvedText: "\(item.approved)",
            windowDays: String(item.windowDays),
            amount: String(format: "%.2f", item.amount),
            refills: String(item.refills),
            capacity: String(item.capacity),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingSubstitutionAllocationViews(_ items: [PendingSubstitutionAllocation]) -> [PendingSubstitutionAllocationView] {
        var views: [PendingSubstitutionAllocationView] = []
        for item in items {
            views.append(toPendingSubstitutionAllocationView(item))
        }
        return views
    }

    static func sumPendingSubstitutionAllocationView(_ view: PendingSubstitutionAllocationView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedVersion) + Double(parsedWindowDays) + parsedAmount
    }
}
