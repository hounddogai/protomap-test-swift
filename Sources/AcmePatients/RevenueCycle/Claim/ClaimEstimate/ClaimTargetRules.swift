import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim target must pass. Check returns its problems, or none.
    protocol ClaimTargetRule {
        func check(_ item: ClaimTarget) -> [String]
    }

    final class ClaimTargetPriorityRangeRule: ClaimTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimTarget) -> [String] {
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

    final class ClaimTargetAllowedNameRule: ClaimTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    final class ClaimTargetLocaleLengthRule: ClaimTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimTarget) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimTargetNameLengthRule: ClaimTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimTargetRequiredLocaleRule: ClaimTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimTarget) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a claim target.
    final class ClaimTargetValidator {
        var rules: [any ClaimTargetRule]

        init(rules: [any ClaimTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimTarget]) -> [String: [String]] {
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

    static func defaultClaimTargetValidator() -> ClaimTargetValidator {
        return ClaimTargetValidator(
            rules: [
                ClaimTargetPriorityRangeRule(min: 32, max: 255),
                ClaimTargetAllowedNameRule(allowed: []),
                ClaimTargetLocaleLengthRule(maxLength: 80),
                ClaimTargetNameLengthRule(maxLength: 3600),
                ClaimTargetRequiredLocaleRule(message: "claim target needs an entry"),
            ]
        )
    }
}
