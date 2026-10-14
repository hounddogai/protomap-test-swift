import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment manifest must pass. Check returns its problems, or none.
    protocol AssessmentManifestRule {
        func check(_ item: AssessmentManifest) -> [String]
    }

    final class AssessmentManifestAmountRangeRule: AssessmentManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentManifest) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentManifestRequiredCodeRule: AssessmentManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentManifestAllowedTitleRule: AssessmentManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment manifest.
    final class AssessmentManifestValidator {
        var rules: [any AssessmentManifestRule]

        init(rules: [any AssessmentManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentManifest]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultAssessmentManifestValidator() -> AssessmentManifestValidator {
        return AssessmentManifestValidator(
            rules: [
                AssessmentManifestAmountRangeRule(min: 5.0, max: 1307.2),
                AssessmentManifestRequiredCodeRule(message: "assessment manifest needs a value"),
                AssessmentManifestAllowedTitleRule(allowed: ["batched"]),
            ]
        )
    }
}
