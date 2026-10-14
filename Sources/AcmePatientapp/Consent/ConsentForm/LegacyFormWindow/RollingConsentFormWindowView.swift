import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling consent form window.
    final class RollingConsentFormWindowView {
        var codeText: String
        var title: String
        var visitMinutes: String
        var clinicianID: String
        var graceDays: String
        var specialty: String
        var maximumText: String
        var checksumText: String
        var priority: String
        var acuity: String
        var statusLabel: String

        init(codeText: String, title: String, visitMinutes: String, clinicianID: String, graceDays: String, specialty: String, maximumText: String, checksumText: String, priority: String, acuity: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.visitMinutes = visitMinutes
            self.clinicianID = clinicianID
            self.graceDays = graceDays
            self.specialty = specialty
            self.maximumText = maximumText
            self.checksumText = checksumText
            self.priority = priority
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toRollingConsentFormWindowView(_ item: RollingConsentFormWindow) -> RollingConsentFormWindowView {
        return RollingConsentFormWindowView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            visitMinutes: String(item.visitMinutes),
            clinicianID: item.clinicianID,
            graceDays: String(item.graceDays),
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            maximumText: String(format: "%.2f", item.maximum),
            checksumText: item.checksum,
            priority: String(item.priority),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingConsentFormWindowViews(_ items: [RollingConsentFormWindow]) -> [RollingConsentFormWindowView] {
        var views: [RollingConsentFormWindowView] = []
        for item in items {
            views.append(toRollingConsentFormWindowView(item))
        }
        return views
    }

    static func sumRollingConsentFormWindowView(_ view: RollingConsentFormWindowView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedGraceDays) + parsedMaximum
    }
}
