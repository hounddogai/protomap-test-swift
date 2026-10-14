import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped isolation score must pass. Check returns its problems, or none.
    protocol CappedIsolationScoreRule {
        func check(_ item: CappedIsolationScore) -> [String]
    }

    final class CappedIsolationScoreNameLengthRule: CappedIsolationScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedIsolationScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedIsolationScoreThresholdRangeRule: CappedIsolationScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedIsolationScore) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedIsolationScoreSpecialtyLengthRule: CappedIsolationScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedIsolationScore) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedIsolationScoreRequiredTimezoneRule: CappedIsolationScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedIsolationScore) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped isolation score.
    final class CappedIsolationScoreValidator {
        var rules: [any CappedIsolationScoreRule]

        init(rules: [any CappedIsolationScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedIsolationScore) -> [String] {
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

        func requireValid(_ item: CappedIsolationScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedIsolationScore]) -> [String: [String]] {
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

    static func defaultCappedIsolationScoreValidator() -> CappedIsolationScoreValidator {
        return CappedIsolationScoreValidator(
            rules: [
                CappedIsolationScoreNameLengthRule(maxLength: 255),
                CappedIsolationScoreThresholdRangeRule(min: 0.6, max: 3440.8),
                CappedIsolationScoreSpecialtyLengthRule(maxLength: 64),
                CappedIsolationScoreRequiredTimezoneRule(message: "capped isolation score needs an entry"),
            ]
        )
    }
}
