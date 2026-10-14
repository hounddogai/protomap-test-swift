import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary task exception.
    final class PrimaryTaskExceptionView {
        var codeText: String
        var label: String
        var active: String
        var copay: String
        var sequence: String
        var statusLabel: String

        init(codeText: String, label: String, active: String, copay: String, sequence: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.active = active
            self.copay = copay
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryTaskExceptionView(_ item: PrimaryTaskException) -> PrimaryTaskExceptionView {
        return PrimaryTaskExceptionView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 64),
            active: "\(item.active)",
            copay: String(format: "%.2f", item.copay),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryTaskExceptionViews(_ items: [PrimaryTaskException]) -> [PrimaryTaskExceptionView] {
        var views: [PrimaryTaskExceptionView] = []
        for item in items {
            views.append(toPrimaryTaskExceptionView(item))
        }
        return views
    }

    static func sumPrimaryTaskExceptionView(_ view: PrimaryTaskExceptionView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedCopay + Double(parsedSequence)
    }
}
