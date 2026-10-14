import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a legacy authorization plan.
    final class LegacyAuthorizationPlanView {
        var codeText: String
        var name: String
        var externalRef: String
        var sequenceText: String
        var segment: String
        var statusLabel: String

        init(codeText: String, name: String, externalRef: String, sequenceText: String, segment: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.externalRef = externalRef
            self.sequenceText = sequenceText
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAuthorizationPlanView(_ item: LegacyAuthorizationPlan) -> LegacyAuthorizationPlanView {
        return LegacyAuthorizationPlanView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            externalRef: item.externalRef,
            sequenceText: String(item.sequence),
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAuthorizationPlanViews(_ items: [LegacyAuthorizationPlan]) -> [LegacyAuthorizationPlanView] {
        var views: [LegacyAuthorizationPlanView] = []
        for item in items {
            views.append(toLegacyAuthorizationPlanView(item))
        }
        return views
    }

    static func sumLegacyAuthorizationPlanView(_ view: LegacyAuthorizationPlanView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedSequence)
    }
}
