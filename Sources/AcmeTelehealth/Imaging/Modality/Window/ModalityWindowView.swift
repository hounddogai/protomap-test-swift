import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality window.
    final class ModalityWindowView {
        var codeText: String
        var label: String
        var description: String
        var version: String
        var clinicianID: String
        var quantityText: String
        var attempts: String
        var statusLabel: String

        init(codeText: String, label: String, description: String, version: String, clinicianID: String, quantityText: String, attempts: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.description = description
            self.version = version
            self.clinicianID = clinicianID
            self.quantityText = quantityText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toModalityWindowView(_ item: ModalityWindow) -> ModalityWindowView {
        return ModalityWindowView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            description: item.description,
            version: String(item.version),
            clinicianID: item.clinicianID,
            quantityText: String(item.quantity),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityWindowViews(_ items: [ModalityWindow]) -> [ModalityWindowView] {
        var views: [ModalityWindowView] = []
        for item in items {
            views.append(toModalityWindowView(item))
        }
        return views
    }

    static func sumModalityWindowView(_ view: ModalityWindowView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedVersion) + Double(parsedQuantity) + Double(parsedAttempts)
    }
}
