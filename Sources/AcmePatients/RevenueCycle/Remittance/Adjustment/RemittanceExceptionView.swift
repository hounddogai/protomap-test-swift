import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance exception.
    final class RemittanceExceptionView {
        var code: String
        var name: String
        var currency: String
        var createdAt: String
        var checksum: String
        var windowDays: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, name: String, currency: String, createdAt: String, checksum: String, windowDays: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.currency = currency
            self.createdAt = createdAt
            self.checksum = checksum
            self.windowDays = windowDays
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceExceptionView(_ item: RemittanceException) -> RemittanceExceptionView {
        return RemittanceExceptionView(
            code: item.code,
            name: item.name,
            currency: item.currency,
            createdAt: String(item.createdAt),
            checksum: item.checksum,
            windowDays: String(item.windowDays),
            clinicianIDText: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceExceptionViews(_ items: [RemittanceException]) -> [RemittanceExceptionView] {
        var views: [RemittanceExceptionView] = []
        for item in items {
            views.append(toRemittanceExceptionView(item))
        }
        return views
    }

    static func sumRemittanceExceptionView(_ view: RemittanceExceptionView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedWindowDays)
    }
}
