import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global isolation window must pass. Check returns its problems, or none.
    protocol GlobalIsolationWindowRule {
        func check(_ item: GlobalIsolationWindow) -> [String]
    }

    final class GlobalIsolationWindowDosageMgRangeRule: GlobalIsolationWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalIsolationWindow) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalIsolationWindowAllowedCodeRule: GlobalIsolationWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalIsolationWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class GlobalIsolationWindowCodeLengthRule: GlobalIsolationWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalIsolationWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global isolation window.
    final class GlobalIsolationWindowValidator {
        var rules: [any GlobalIsolationWindowRule]

        init(rules: [any GlobalIsolationWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalIsolationWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalIsolationWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalIsolationWindow]) -> [String: [String]] {
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

    static func defaultGlobalIsolationWindowValidator() -> GlobalIsolationWindowValidator {
        return GlobalIsolationWindowValidator(
            rules: [
                GlobalIsolationWindowDosageMgRangeRule(min: 1.3, max: 2845.3),
                GlobalIsolationWindowAllowedCodeRule(allowed: ["global", "capped"]),
                GlobalIsolationWindowCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
