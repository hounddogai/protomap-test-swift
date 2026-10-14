import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial target must pass. Check returns its problems, or none.
    protocol DenialTargetRule {
        func check(_ item: DenialTarget) -> [String]
    }

    final class DenialTargetRequiredTitleRule: DenialTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialTarget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialTargetPinnedGuardRule: DenialTargetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DenialTarget) -> [String] {
            if item.pinned && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class DenialTargetRefillsRangeRule: DenialTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialTarget) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialTargetTitleLengthRule: DenialTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialTarget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialTargetCodePrefixRule: DenialTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial target.
    final class DenialTargetValidator {
        var rules: [any DenialTargetRule]

        init(rules: [any DenialTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialTarget]) -> [String: [String]] {
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

    static func defaultDenialTargetValidator() -> DenialTargetValidator {
        return DenialTargetValidator(
            rules: [
                DenialTargetRequiredTitleRule(message: "denial target needs an entry"),
                DenialTargetPinnedGuardRule(limit: 86400),
                DenialTargetRefillsRangeRule(min: 120, max: 1000),
                DenialTargetTitleLengthRule(maxLength: 64),
                DenialTargetCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
