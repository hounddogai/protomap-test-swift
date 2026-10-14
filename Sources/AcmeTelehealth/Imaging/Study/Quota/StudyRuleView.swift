import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study rule.
    final class StudyRuleView {
        var code: String
        var name: String
        var attempts: String
        var version: String
        var refills: String
        var unit: String
        var batchSizeText: String
        var rate: String
        var statusLabel: String

        init(code: String, name: String, attempts: String, version: String, refills: String, unit: String, batchSizeText: String, rate: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.version = version
            self.refills = refills
            self.unit = unit
            self.batchSizeText = batchSizeText
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toStudyRuleView(_ item: StudyRule) -> StudyRuleView {
        return StudyRuleView(
            code: item.code,
            name: item.name,
            attempts: String(item.attempts),
            version: String(item.version),
            refills: String(item.refills),
            unit: item.unit,
            batchSizeText: String(item.batchSize),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyRuleViews(_ items: [StudyRule]) -> [StudyRuleView] {
        var views: [StudyRuleView] = []
        for item in items {
            views.append(toStudyRuleView(item))
        }
        return views
    }

    static func sumStudyRuleView(_ view: StudyRuleView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedAttempts) + Double(parsedVersion) + Double(parsedRefills)
    }
}
