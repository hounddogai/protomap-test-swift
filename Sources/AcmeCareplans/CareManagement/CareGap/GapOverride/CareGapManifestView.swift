import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap manifest.
    final class CareGapManifestView {
        var code: String
        var title: String
        var windowDays: String
        var rate: String
        var amountText: String
        var phone: String
        var procedureCodeText: String
        var versionText: String
        var refills: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, title: String, windowDays: String, rate: String, amountText: String, phone: String, procedureCodeText: String, versionText: String, refills: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.rate = rate
            self.amountText = amountText
            self.phone = phone
            self.procedureCodeText = procedureCodeText
            self.versionText = versionText
            self.refills = refills
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapManifestView(_ item: CareGapManifest) -> CareGapManifestView {
        return CareGapManifestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            windowDays: String(item.windowDays),
            rate: String(format: "%.2f", item.rate),
            amountText: String(format: "%.2f", item.amount),
            phone: Kit.Text.truncate(item.phone, limit: 80),
            procedureCodeText: item.procedureCode,
            versionText: String(item.version),
            refills: String(item.refills),
            clinicianIDText: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapManifestViews(_ items: [CareGapManifest]) -> [CareGapManifestView] {
        var views: [CareGapManifestView] = []
        for item in items {
            views.append(toCareGapManifestView(item))
        }
        return views
    }

    static func sumCareGapManifestView(_ view: CareGapManifestView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedWindowDays) + parsedRate + parsedAmount
    }
}
