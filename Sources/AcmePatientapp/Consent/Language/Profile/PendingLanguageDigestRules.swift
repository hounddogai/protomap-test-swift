import AcmePlatform
import Foundation

extension Consent {
    /// A rule a pending language digest must pass. Check returns its problems, or none.
    protocol PendingLanguageDigestRule {
        func check(_ item: PendingLanguageDigest) -> [String]
    }

    final class PendingLanguageDigestPriorityRangeRule: PendingLanguageDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingLanguageDigest) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingLanguageDigestRequiredBedRule: PendingLanguageDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingLanguageDigest) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingLanguageDigestCodePrefixRule: PendingLanguageDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingLanguageDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingLanguageDigestCostRangeRule: PendingLanguageDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingLanguageDigest) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending language digest.
    final class PendingLanguageDigestValidator {
        var rules: [any PendingLanguageDigestRule]

        init(rules: [any PendingLanguageDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingLanguageDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingLanguageDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingLanguageDigest]) -> [String: [String]] {
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

    static func defaultPendingLanguageDigestValidator() -> PendingLanguageDigestValidator {
        return PendingLanguageDigestValidator(
            rules: [
                PendingLanguageDigestPriorityRangeRule(min: 32, max: 64),
                PendingLanguageDigestRequiredBedRule(message: "pending language digest needs an entry"),
                PendingLanguageDigestCodePrefixRule(prefix: "OPS"),
                PendingLanguageDigestCostRangeRule(min: 6.0, max: 3154.6),
            ]
        )
    }
}
