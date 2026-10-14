import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure baseline must pass. Check returns its problems, or none.
    protocol ClosureBaselineRule {
        func check(_ item: ClosureBaseline) -> [String]
    }

    final class ClosureBaselineLabelLengthRule: ClosureBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureBaselineCreatedAtRangeRule: ClosureBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureBaseline) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosureBaselineRequiredDiagnosisCodeRule: ClosureBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureBaseline) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureBaselineExpiresAtRangeRule: ClosureBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureBaseline) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure baseline.
    final class ClosureBaselineValidator {
        var rules: [any ClosureBaselineRule]

        init(rules: [any ClosureBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureBaseline) -> [String] {
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

        func requireValid(_ item: ClosureBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureBaseline]) -> [String: [String]] {
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

    static func defaultClosureBaselineValidator() -> ClosureBaselineValidator {
        return ClosureBaselineValidator(
            rules: [
                ClosureBaselineLabelLengthRule(maxLength: 3600),
                ClosureBaselineCreatedAtRangeRule(min: 16, max: 86400),
                ClosureBaselineRequiredDiagnosisCodeRule(message: "closure baseline needs this field"),
                ClosureBaselineExpiresAtRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
