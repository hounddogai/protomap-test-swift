import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive specimen reservation.
    final class AdaptiveSpecimenReservationView {
        var codeText: String
        var title: String
        var phone: String
        var region: String
        var threshold: String
        var channelText: String
        var visibleText: String
        var windowDays: String
        var version: String
        var statusLabel: String

        init(codeText: String, title: String, phone: String, region: String, threshold: String, channelText: String, visibleText: String, windowDays: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.phone = phone
            self.region = region
            self.threshold = threshold
            self.channelText = channelText
            self.visibleText = visibleText
            self.windowDays = windowDays
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveSpecimenReservationView(_ item: AdaptiveSpecimenReservation) -> AdaptiveSpecimenReservationView {
        return AdaptiveSpecimenReservationView(
            codeText: item.code,
            title: item.title,
            phone: item.phone,
            region: Kit.Text.truncate(item.region, limit: 40),
            threshold: String(format: "%.2f", item.threshold),
            channelText: item.channel,
            visibleText: "\(item.visible)",
            windowDays: String(item.windowDays),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveSpecimenReservationViews(_ items: [AdaptiveSpecimenReservation]) -> [AdaptiveSpecimenReservationView] {
        var views: [AdaptiveSpecimenReservationView] = []
        for item in items {
            views.append(toAdaptiveSpecimenReservationView(item))
        }
        return views
    }

    static func sumAdaptiveSpecimenReservationView(_ view: AdaptiveSpecimenReservationView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedThreshold + Double(parsedWindowDays) + Double(parsedVersion)
    }
}
