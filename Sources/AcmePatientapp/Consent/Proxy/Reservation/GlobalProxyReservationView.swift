import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a global proxy reservation.
    final class GlobalProxyReservationView {
        var codeText: String
        var label: String
        var revision: String
        var approved: String
        var retries: String
        var copayText: String
        var channel: String
        var regionText: String
        var ward: String
        var attemptsText: String
        var statusLabel: String

        init(codeText: String, label: String, revision: String, approved: String, retries: String, copayText: String, channel: String, regionText: String, ward: String, attemptsText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.revision = revision
            self.approved = approved
            self.retries = retries
            self.copayText = copayText
            self.channel = channel
            self.regionText = regionText
            self.ward = ward
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalProxyReservationView(_ item: GlobalProxyReservation) -> GlobalProxyReservationView {
        return GlobalProxyReservationView(
            codeText: item.code,
            label: item.label,
            revision: String(item.revision),
            approved: "\(item.approved)",
            retries: String(item.retries),
            copayText: String(format: "%.2f", item.copay),
            channel: item.channel,
            regionText: item.region,
            ward: item.ward,
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalProxyReservationViews(_ items: [GlobalProxyReservation]) -> [GlobalProxyReservationView] {
        var views: [GlobalProxyReservationView] = []
        for item in items {
            views.append(toGlobalProxyReservationView(item))
        }
        return views
    }

    static func sumGlobalProxyReservationView(_ view: GlobalProxyReservationView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedRevision) + Double(parsedRetries) + parsedCopay
    }
}
