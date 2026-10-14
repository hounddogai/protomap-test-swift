import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient cleaning request.
    final class LenientCleaningRequestView {
        var code: String
        var name: String
        var visibleText: String
        var checksum: String
        var dosageMg: String
        var locale: String
        var phoneText: String
        var budget: String
        var statusLabel: String

        init(code: String, name: String, visibleText: String, checksum: String, dosageMg: String, locale: String, phoneText: String, budget: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visibleText = visibleText
            self.checksum = checksum
            self.dosageMg = dosageMg
            self.locale = locale
            self.phoneText = phoneText
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCleaningRequestView(_ item: LenientCleaningRequest) -> LenientCleaningRequestView {
        return LenientCleaningRequestView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            visibleText: "\(item.visible)",
            checksum: item.checksum,
            dosageMg: String(format: "%.2f", item.dosageMg),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            phoneText: Kit.Text.truncate(item.phone, limit: 40),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCleaningRequestViews(_ items: [LenientCleaningRequest]) -> [LenientCleaningRequestView] {
        var views: [LenientCleaningRequestView] = []
        for item in items {
            views.append(toLenientCleaningRequestView(item))
        }
        return views
    }

    static func sumLenientCleaningRequestView(_ view: LenientCleaningRequestView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedDosageMg + parsedBudget
    }
}
