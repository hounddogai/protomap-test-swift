import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a default slot request.
    final class DefaultSlotRequestView {
        var code: String
        var labelText: String
        var dosageMgText: String
        var ratioText: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, labelText: String, dosageMgText: String, ratioText: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.dosageMgText = dosageMgText
            self.ratioText = ratioText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultSlotRequestView(_ item: DefaultSlotRequest) -> DefaultSlotRequestView {
        return DefaultSlotRequestView(
            code: item.code,
            labelText: item.label,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            ratioText: String(format: "%.2f", item.ratio),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultSlotRequestViews(_ items: [DefaultSlotRequest]) -> [DefaultSlotRequestView] {
        var views: [DefaultSlotRequestView] = []
        for item in items {
            views.append(toDefaultSlotRequestView(item))
        }
        return views
    }

    static func sumDefaultSlotRequestView(_ view: DefaultSlotRequestView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedDosageMg + parsedRatio
    }
}
