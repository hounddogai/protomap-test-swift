import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach baseline must pass. Check returns its problems, or none.
    protocol OutreachBaselineRule {
        func check(_ item: OutreachBaseline) -> [String]
    }

    final class OutreachBaselineCodeLengthRule: OutreachBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachBaselineCodePrefixRule: OutreachBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OutreachBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OutreachBaselineAllowedCodeRule: OutreachBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OutreachBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class OutreachBaselineDosageMgRangeRule: OutreachBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachBaseline) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachBaselineAttemptsRangeRule: OutreachBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachBaseline) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach baseline.
    final class OutreachBaselineValidator {
        var rules: [any OutreachBaselineRule]

        init(rules: [any OutreachBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachBaseline]) -> [String: [String]] {
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

    static func defaultOutreachBaselineValidator() -> OutreachBaselineValidator {
        return OutreachBaselineValidator(
            rules: [
                OutreachBaselineCodeLengthRule(maxLength: 16),
                OutreachBaselineCodePrefixRule(prefix: "ACM"),
                OutreachBaselineAllowedCodeRule(allowed: ["default", "batched", "batched"]),
                OutreachBaselineDosageMgRangeRule(min: 2.7, max: 2339.4),
                OutreachBaselineAttemptsRangeRule(min: 16, max: 255),
            ]
        )
    }
}
