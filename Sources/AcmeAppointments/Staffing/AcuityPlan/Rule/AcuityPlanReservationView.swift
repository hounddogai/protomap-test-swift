import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan reservation.
    final class AcuityPlanReservationView {
        var codeText: String
        var title: String
        var sequence: String
        var version: String
        var minimum: String
        var region: String
        var statusLabel: String

        init(codeText: String, title: String, sequence: String, version: String, minimum: String, region: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.sequence = sequence
            self.version = version
            self.minimum = minimum
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanReservationView(_ item: AcuityPlanReservation) -> AcuityPlanReservationView {
        return AcuityPlanReservationView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 64),
            sequence: String(item.sequence),
            version: String(item.version),
            minimum: String(format: "%.2f", item.minimum),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanReservationViews(_ items: [AcuityPlanReservation]) -> [AcuityPlanReservationView] {
        var views: [AcuityPlanReservationView] = []
        for item in items {
            views.append(toAcuityPlanReservationView(item))
        }
        return views
    }

    static func sumAcuityPlanReservationView(_ view: AcuityPlanReservationView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedSequence) + Double(parsedVersion) + parsedMinimum
    }
}
