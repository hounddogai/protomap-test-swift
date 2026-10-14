import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score allocation must pass. Check returns its problems, or none.
    protocol RiskScoreAllocationRule {
        func check(_ item: RiskScoreAllocation) -> [String]
    }

    final class RiskScoreAllocationWardLengthRule: RiskScoreAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreAllocation) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreAllocationActiveGuardRule: RiskScoreAllocationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RiskScoreAllocation) -> [String] {
            if item.active && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class RiskScoreAllocationCodePrefixRule: RiskScoreAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreAllocationAllowedTitleRule: RiskScoreAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class RiskScoreAllocationTitleLengthRule: RiskScoreAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score allocation.
    final class RiskScoreAllocationValidator {
        var rules: [any RiskScoreAllocationRule]

        init(rules: [any RiskScoreAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreAllocation]) -> [String: [String]] {
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

    static func defaultRiskScoreAllocationValidator() -> RiskScoreAllocationValidator {
        return RiskScoreAllocationValidator(
            rules: [
                RiskScoreAllocationWardLengthRule(maxLength: 1000),
                RiskScoreAllocationActiveGuardRule(limit: 1.3),
                RiskScoreAllocationCodePrefixRule(prefix: "Q"),
                RiskScoreAllocationAllowedTitleRule(allowed: ["capped", "legacy"]),
                RiskScoreAllocationTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
