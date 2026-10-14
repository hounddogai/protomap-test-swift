import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a adaptive program exception.
    final class AdaptiveProgramExceptionView {
        var codeText: String
        var titleText: String
        var externalRef: String
        var acuity: String
        var amount: String
        var nameText: String
        var statusLabel: String

        init(codeText: String, titleText: String, externalRef: String, acuity: String, amount: String, nameText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.externalRef = externalRef
            self.acuity = acuity
            self.amount = amount
            self.nameText = nameText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveProgramExceptionView(_ item: AdaptiveProgramException) -> AdaptiveProgramExceptionView {
        return AdaptiveProgramExceptionView(
            codeText: item.code,
            titleText: item.title,
            externalRef: item.externalRef,
            acuity: String(item.acuity),
            amount: String(format: "%.2f", item.amount),
            nameText: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveProgramExceptionViews(_ items: [AdaptiveProgramException]) -> [AdaptiveProgramExceptionView] {
        var views: [AdaptiveProgramExceptionView] = []
        for item in items {
            views.append(toAdaptiveProgramExceptionView(item))
        }
        return views
    }

    static func sumAdaptiveProgramExceptionView(_ view: AdaptiveProgramExceptionView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedAcuity) + parsedAmount
    }
}
