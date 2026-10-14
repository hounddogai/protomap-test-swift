import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance snapshot.
    final class RemittanceSnapshotView {
        var code: String
        var name: String
        var dosageMg: String
        var expiresAt: String
        var facility: String
        var visitMinutesText: String
        var visibleText: String
        var countryText: String
        var statusLabel: String

        init(code: String, name: String, dosageMg: String, expiresAt: String, facility: String, visitMinutesText: String, visibleText: String, countryText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.expiresAt = expiresAt
            self.facility = facility
            self.visitMinutesText = visitMinutesText
            self.visibleText = visibleText
            self.countryText = countryText
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceSnapshotView(_ item: RemittanceSnapshot) -> RemittanceSnapshotView {
        return RemittanceSnapshotView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            dosageMg: String(format: "%.2f", item.dosageMg),
            expiresAt: String(item.expiresAt),
            facility: Kit.Text.truncate(item.facility, limit: 64),
            visitMinutesText: String(item.visitMinutes),
            visibleText: "\(item.visible)",
            countryText: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceSnapshotViews(_ items: [RemittanceSnapshot]) -> [RemittanceSnapshotView] {
        var views: [RemittanceSnapshotView] = []
        for item in items {
            views.append(toRemittanceSnapshotView(item))
        }
        return views
    }

    static func sumRemittanceSnapshotView(_ view: RemittanceSnapshotView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedDosageMg + Double(parsedExpiresAt) + Double(parsedVisitMinutes)
    }
}
