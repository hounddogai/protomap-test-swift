import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement mapping.
    final class StatementMappingView {
        var code: String
        var title: String
        var revisionText: String
        var acuityText: String
        var procedureCodeText: String
        var specialty: String
        var ward: String
        var minimum: String
        var ceiling: String
        var currency: String
        var statusLabel: String

        init(code: String, title: String, revisionText: String, acuityText: String, procedureCodeText: String, specialty: String, ward: String, minimum: String, ceiling: String, currency: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revisionText = revisionText
            self.acuityText = acuityText
            self.procedureCodeText = procedureCodeText
            self.specialty = specialty
            self.ward = ward
            self.minimum = minimum
            self.ceiling = ceiling
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toStatementMappingView(_ item: StatementMapping) -> StatementMappingView {
        return StatementMappingView(
            code: item.code,
            title: item.title,
            revisionText: String(item.revision),
            acuityText: String(item.acuity),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 120),
            specialty: item.specialty,
            ward: Kit.Text.truncate(item.ward, limit: 64),
            minimum: String(format: "%.2f", item.minimum),
            ceiling: String(format: "%.2f", item.ceiling),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementMappingViews(_ items: [StatementMapping]) -> [StatementMappingView] {
        var views: [StatementMappingView] = []
        for item in items {
            views.append(toStatementMappingView(item))
        }
        return views
    }

    static func sumStatementMappingView(_ view: StatementMappingView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedRevision) + Double(parsedAcuity) + parsedMinimum
    }
}
