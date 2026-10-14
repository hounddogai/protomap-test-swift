import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure checkpoint must pass. Check returns its problems, or none.
    protocol ClosureCheckpointRule {
        func check(_ item: ClosureCheckpoint) -> [String]
    }

    final class ClosureCheckpointCodeLengthRule: ClosureCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureCheckpointWindowDaysRangeRule: ClosureCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureCheckpoint) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosureCheckpointAllowedDiagnosisCodeRule: ClosureCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosureCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is missing"]
            }
            return []
        }
    }

    final class ClosureCheckpointCodePrefixRule: ClosureCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure checkpoint.
    final class ClosureCheckpointValidator {
        var rules: [any ClosureCheckpointRule]

        init(rules: [any ClosureCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureCheckpoint) -> [String] {
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

        func requireValid(_ item: ClosureCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureCheckpoint]) -> [String: [String]] {
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

    static func defaultClosureCheckpointValidator() -> ClosureCheckpointValidator {
        return ClosureCheckpointValidator(
            rules: [
                ClosureCheckpointCodeLengthRule(maxLength: 64),
                ClosureCheckpointWindowDaysRangeRule(min: 32, max: 1000),
                ClosureCheckpointAllowedDiagnosisCodeRule(allowed: ["capped", "tiered", "adaptive"]),
                ClosureCheckpointCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
