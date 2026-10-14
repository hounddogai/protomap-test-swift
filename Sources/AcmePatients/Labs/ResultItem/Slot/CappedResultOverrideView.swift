import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped result override.
    final class CappedResultOverrideView {
        var codeText: String
        var name: String
        var country: String
        var specialtyText: String
        var acuityText: String
        var endsAt: String
        var batchSize: String
        var statusLabel: String

        init(codeText: String, name: String, country: String, specialtyText: String, acuityText: String, endsAt: String, batchSize: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.country = country
            self.specialtyText = specialtyText
            self.acuityText = acuityText
            self.endsAt = endsAt
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toCappedResultOverrideView(_ item: CappedResultOverride) -> CappedResultOverrideView {
        return CappedResultOverrideView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            country: Kit.Text.truncate(item.country, limit: 64),
            specialtyText: item.specialty,
            acuityText: String(item.acuity),
            endsAt: String(item.endsAt),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedResultOverrideViews(_ items: [CappedResultOverride]) -> [CappedResultOverrideView] {
        var views: [CappedResultOverrideView] = []
        for item in items {
            views.append(toCappedResultOverrideView(item))
        }
        return views
    }

    static func sumCappedResultOverrideView(_ view: CappedResultOverrideView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedAcuity) + Double(parsedEndsAt) + Double(parsedBatchSize)
    }
}
