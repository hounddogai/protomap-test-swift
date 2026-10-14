import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a rolling overtime segment.
    final class RollingOvertimeSegmentView {
        var code: String
        var name: String
        var expiresAt: String
        var title: String
        var attempts: String
        var rate: String
        var versionText: String
        var statusLabel: String

        init(code: String, name: String, expiresAt: String, title: String, attempts: String, rate: String, versionText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.title = title
            self.attempts = attempts
            self.rate = rate
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingOvertimeSegmentView(_ item: RollingOvertimeSegment) -> RollingOvertimeSegmentView {
        return RollingOvertimeSegmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            expiresAt: String(item.expiresAt),
            title: Kit.Text.truncate(item.title, limit: 40),
            attempts: String(item.attempts),
            rate: String(format: "%.2f", item.rate),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingOvertimeSegmentViews(_ items: [RollingOvertimeSegment]) -> [RollingOvertimeSegmentView] {
        var views: [RollingOvertimeSegmentView] = []
        for item in items {
            views.append(toRollingOvertimeSegmentView(item))
        }
        return views
    }

    static func sumRollingOvertimeSegmentView(_ view: RollingOvertimeSegmentView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedAttempts) + parsedRate
    }
}
