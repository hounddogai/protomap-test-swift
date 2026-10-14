import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback credential target.
    final class FallbackCredentialTargetView {
        var code: String
        var label: String
        var versionText: String
        var priority: String
        var bed: String
        var segment: String
        var pinned: String
        var statusLabel: String

        init(code: String, label: String, versionText: String, priority: String, bed: String, segment: String, pinned: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.versionText = versionText
            self.priority = priority
            self.bed = bed
            self.segment = segment
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCredentialTargetView(_ item: FallbackCredentialTarget) -> FallbackCredentialTargetView {
        return FallbackCredentialTargetView(
            code: item.code,
            label: item.label,
            versionText: String(item.version),
            priority: String(item.priority),
            bed: Kit.Text.truncate(item.bed, limit: 120),
            segment: item.segment,
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCredentialTargetViews(_ items: [FallbackCredentialTarget]) -> [FallbackCredentialTargetView] {
        var views: [FallbackCredentialTargetView] = []
        for item in items {
            views.append(toFallbackCredentialTargetView(item))
        }
        return views
    }

    static func sumFallbackCredentialTargetView(_ view: FallbackCredentialTargetView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedVersion) + Double(parsedPriority)
    }
}
