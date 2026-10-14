import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization cycle.
    final class AuthorizationCycleView {
        var code: String
        var nameText: String
        var allergy: String
        var threshold: String
        var externalRef: String
        var acuityText: String
        var windowDays: String
        var batchSizeText: String
        var copay: String
        var revision: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, nameText: String, allergy: String, threshold: String, externalRef: String, acuityText: String, windowDays: String, batchSizeText: String, copay: String, revision: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.allergy = allergy
            self.threshold = threshold
            self.externalRef = externalRef
            self.acuityText = acuityText
            self.windowDays = windowDays
            self.batchSizeText = batchSizeText
            self.copay = copay
            self.revision = revision
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationCycleView(_ item: AuthorizationCycle) -> AuthorizationCycleView {
        return AuthorizationCycleView(
            code: item.code,
            nameText: item.name,
            allergy: item.allergy,
            threshold: String(format: "%.2f", item.threshold),
            externalRef: item.externalRef,
            acuityText: String(item.acuity),
            windowDays: String(item.windowDays),
            batchSizeText: String(item.batchSize),
            copay: String(format: "%.2f", item.copay),
            revision: String(item.revision),
            reviewerText: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationCycleViews(_ items: [AuthorizationCycle]) -> [AuthorizationCycleView] {
        var views: [AuthorizationCycleView] = []
        for item in items {
            views.append(toAuthorizationCycleView(item))
        }
        return views
    }

    static func sumAuthorizationCycleView(_ view: AuthorizationCycleView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedThreshold + Double(parsedAcuity) + Double(parsedWindowDays)
    }
}
