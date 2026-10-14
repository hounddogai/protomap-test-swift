import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary checkpoint.
    final class FormularyCheckpointView {
        var code: String
        var name: String
        var title: String
        var checksum: String
        var updatedAtText: String
        var specialtyText: String
        var channel: String
        var allergy: String
        var categoryText: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, title: String, checksum: String, updatedAtText: String, specialtyText: String, channel: String, allergy: String, categoryText: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.title = title
            self.checksum = checksum
            self.updatedAtText = updatedAtText
            self.specialtyText = specialtyText
            self.channel = channel
            self.allergy = allergy
            self.categoryText = categoryText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyCheckpointView(_ item: FormularyCheckpoint) -> FormularyCheckpointView {
        return FormularyCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            title: Kit.Text.truncate(item.title, limit: 80),
            checksum: item.checksum,
            updatedAtText: String(item.updatedAt),
            specialtyText: item.specialty,
            channel: Kit.Text.truncate(item.channel, limit: 64),
            allergy: item.allergy,
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyCheckpointViews(_ items: [FormularyCheckpoint]) -> [FormularyCheckpointView] {
        var views: [FormularyCheckpointView] = []
        for item in items {
            views.append(toFormularyCheckpointView(item))
        }
        return views
    }

    static func sumFormularyCheckpointView(_ view: FormularyCheckpointView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedEndsAt)
    }
}
