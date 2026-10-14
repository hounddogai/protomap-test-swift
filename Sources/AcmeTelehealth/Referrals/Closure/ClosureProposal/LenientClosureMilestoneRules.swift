import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a lenient closure milestone must pass. Check returns its problems, or none.
    protocol LenientClosureMilestoneRule {
        func check(_ item: LenientClosureMilestone) -> [String]
    }

    final class LenientClosureMilestoneCodePrefixRule: LenientClosureMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientClosureMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientClosureMilestoneRequiredRegionRule: LenientClosureMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientClosureMilestone) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientClosureMilestoneCodeLengthRule: LenientClosureMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientClosureMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient closure milestone.
    final class LenientClosureMilestoneValidator {
        var rules: [any LenientClosureMilestoneRule]

        init(rules: [any LenientClosureMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientClosureMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientClosureMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientClosureMilestone]) -> [String: [String]] {
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

    static func defaultLenientClosureMilestoneValidator() -> LenientClosureMilestoneValidator {
        return LenientClosureMilestoneValidator(
            rules: [
                LenientClosureMilestoneCodePrefixRule(prefix: "X"),
                LenientClosureMilestoneRequiredRegionRule(message: "lenient closure milestone needs this field"),
                LenientClosureMilestoneCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
