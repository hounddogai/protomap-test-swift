import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result agreement.
    final class ResultAgreementView {
        var code: String
        var title: String
        var capacity: String
        var copay: String
        var sequence: String
        var activeText: String
        var visibleText: String
        var statusLabel: String

        init(code: String, title: String, capacity: String, copay: String, sequence: String, activeText: String, visibleText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.copay = copay
            self.sequence = sequence
            self.activeText = activeText
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toResultAgreementView(_ item: ResultAgreement) -> ResultAgreementView {
        return ResultAgreementView(
            code: item.code,
            title: item.title,
            capacity: String(item.capacity),
            copay: String(format: "%.2f", item.copay),
            sequence: String(item.sequence),
            activeText: "\(item.active)",
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultAgreementViews(_ items: [ResultAgreement]) -> [ResultAgreementView] {
        var views: [ResultAgreementView] = []
        for item in items {
            views.append(toResultAgreementView(item))
        }
        return views
    }

    static func sumResultAgreementView(_ view: ResultAgreementView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedCapacity) + parsedCopay + Double(parsedSequence)
    }
}
