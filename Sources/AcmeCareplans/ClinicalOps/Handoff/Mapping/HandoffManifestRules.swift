import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff manifest must pass. Check returns its problems, or none.
    protocol HandoffManifestRule {
        func check(_ item: HandoffManifest) -> [String]
    }

    final class HandoffManifestRequiredCodeRule: HandoffManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffManifestAllowedNameRule: HandoffManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: HandoffManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class HandoffManifestRequiredReviewerRule: HandoffManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffManifest) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffManifestReviewerLengthRule: HandoffManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffManifest) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffManifestSequenceRangeRule: HandoffManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffManifest) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a handoff manifest.
    final class HandoffManifestValidator {
        var rules: [any HandoffManifestRule]

        init(rules: [any HandoffManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffManifest]) -> [String: [String]] {
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

    static func defaultHandoffManifestValidator() -> HandoffManifestValidator {
        return HandoffManifestValidator(
            rules: [
                HandoffManifestRequiredCodeRule(message: "handoff manifest needs a value"),
                HandoffManifestAllowedNameRule(allowed: ["strict", "pending"]),
                HandoffManifestRequiredReviewerRule(message: "handoff manifest needs an entry"),
                HandoffManifestReviewerLengthRule(maxLength: 255),
                HandoffManifestSequenceRangeRule(min: 1000, max: 1000),
            ]
        )
    }
}
