import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program quota.
    final class ProgramQuotaView {
        var code: String
        var name: String
        var copay: String
        var encounterID: String
        var localeText: String
        var graceDays: String
        var statusLabel: String

        init(code: String, name: String, copay: String, encounterID: String, localeText: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.copay = copay
            self.encounterID = encounterID
            self.localeText = localeText
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toProgramQuotaView(_ item: ProgramQuota) -> ProgramQuotaView {
        return ProgramQuotaView(
            code: item.code,
            name: item.name,
            copay: String(format: "%.2f", item.copay),
            encounterID: item.encounterID,
            localeText: item.locale,
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramQuotaViews(_ items: [ProgramQuota]) -> [ProgramQuotaView] {
        var views: [ProgramQuotaView] = []
        for item in items {
            views.append(toProgramQuotaView(item))
        }
        return views
    }

    static func sumProgramQuotaView(_ view: ProgramQuotaView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedCopay + Double(parsedGraceDays)
    }
}
