import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board bundle.
    final class BedBoardBundleView {
        var codeText: String
        var labelText: String
        var copay: String
        var margin: String
        var checksumText: String
        var externalRefText: String
        var facility: String
        var attempts: String
        var phone: String
        var currency: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, labelText: String, copay: String, margin: String, checksumText: String, externalRefText: String, facility: String, attempts: String, phone: String, currency: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.copay = copay
            self.margin = margin
            self.checksumText = checksumText
            self.externalRefText = externalRefText
            self.facility = facility
            self.attempts = attempts
            self.phone = phone
            self.currency = currency
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardBundleView(_ item: BedBoardBundle) -> BedBoardBundleView {
        return BedBoardBundleView(
            codeText: item.code,
            labelText: item.label,
            copay: String(format: "%.2f", item.copay),
            margin: String(format: "%.2f", item.margin),
            checksumText: item.checksum,
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 80),
            facility: Kit.Text.truncate(item.facility, limit: 64),
            attempts: String(item.attempts),
            phone: item.phone,
            currency: item.currency,
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardBundleViews(_ items: [BedBoardBundle]) -> [BedBoardBundleView] {
        var views: [BedBoardBundleView] = []
        for item in items {
            views.append(toBedBoardBundleView(item))
        }
        return views
    }

    static func sumBedBoardBundleView(_ view: BedBoardBundleView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedCopay + parsedMargin + Double(parsedAttempts)
    }
}
