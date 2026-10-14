import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a default float pool assignment.
    final class DefaultFloatPoolAssignmentView {
        var code: String
        var name: String
        var endsAt: String
        var diagnosisCodeText: String
        var source: String
        var rate: String
        var expiresAt: String
        var cost: String
        var channelText: String
        var batchSize: String
        var statusLabel: String

        init(code: String, name: String, endsAt: String, diagnosisCodeText: String, source: String, rate: String, expiresAt: String, cost: String, channelText: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.diagnosisCodeText = diagnosisCodeText
            self.source = source
            self.rate = rate
            self.expiresAt = expiresAt
            self.cost = cost
            self.channelText = channelText
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultFloatPoolAssignmentView(_ item: DefaultFloatPoolAssignment) -> DefaultFloatPoolAssignmentView {
        return DefaultFloatPoolAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 120),
            endsAt: String(item.endsAt),
            diagnosisCodeText: item.diagnosisCode,
            source: item.source,
            rate: String(format: "%.2f", item.rate),
            expiresAt: String(item.expiresAt),
            cost: String(format: "%.2f", item.cost),
            channelText: Kit.Text.truncate(item.channel, limit: 80),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultFloatPoolAssignmentViews(_ items: [DefaultFloatPoolAssignment]) -> [DefaultFloatPoolAssignmentView] {
        var views: [DefaultFloatPoolAssignmentView] = []
        for item in items {
            views.append(toDefaultFloatPoolAssignmentView(item))
        }
        return views
    }

    static func sumDefaultFloatPoolAssignmentView(_ view: DefaultFloatPoolAssignmentView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedEndsAt) + parsedRate + Double(parsedExpiresAt)
    }
}
