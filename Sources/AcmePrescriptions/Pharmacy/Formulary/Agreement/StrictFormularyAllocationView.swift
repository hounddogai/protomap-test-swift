import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a strict formulary allocation.
    final class StrictFormularyAllocationView {
        var codeText: String
        var label: String
        var version: String
        var retries: String
        var graceDays: String
        var statusLabel: String

        init(codeText: String, label: String, version: String, retries: String, graceDays: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.version = version
            self.retries = retries
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toStrictFormularyAllocationView(_ item: StrictFormularyAllocation) -> StrictFormularyAllocationView {
        return StrictFormularyAllocationView(
            codeText: item.code,
            label: item.label,
            version: String(item.version),
            retries: String(item.retries),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictFormularyAllocationViews(_ items: [StrictFormularyAllocation]) -> [StrictFormularyAllocationView] {
        var views: [StrictFormularyAllocationView] = []
        for item in items {
            views.append(toStrictFormularyAllocationView(item))
        }
        return views
    }

    static func sumStrictFormularyAllocationView(_ view: StrictFormularyAllocationView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedVersion) + Double(parsedRetries) + Double(parsedGraceDays)
    }
}
