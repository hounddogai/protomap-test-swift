import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive program cycle must pass. Check returns its problems, or none.
    protocol AdaptiveProgramCycleRule {
        func check(_ item: AdaptiveProgramCycle) -> [String]
    }

    final class AdaptiveProgramCycleRefillsRangeRule: AdaptiveProgramCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveProgramCycle) -> [String] {
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

    final class AdaptiveProgramCycleTagsLimitRule: AdaptiveProgramCycleRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: AdaptiveProgramCycle) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class AdaptiveProgramCycleRequiredCodeRule: AdaptiveProgramCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveProgramCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveProgramCycleCodePrefixRule: AdaptiveProgramCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveProgramCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive program cycle.
    final class AdaptiveProgramCycleValidator {
        var rules: [any AdaptiveProgramCycleRule]

        init(rules: [any AdaptiveProgramCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveProgramCycle) -> [String] {
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

        func requireValid(_ item: AdaptiveProgramCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveProgramCycle]) -> [String: [String]] {
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

    static func defaultAdaptiveProgramCycleValidator() -> AdaptiveProgramCycleValidator {
        return AdaptiveProgramCycleValidator(
            rules: [
                AdaptiveProgramCycleRefillsRangeRule(min: 32, max: 64),
                AdaptiveProgramCycleTagsLimitRule(maxCount: 3600, banned: ["regional"]),
                AdaptiveProgramCycleRequiredCodeRule(message: "adaptive program cycle needs an entry"),
                AdaptiveProgramCycleCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
