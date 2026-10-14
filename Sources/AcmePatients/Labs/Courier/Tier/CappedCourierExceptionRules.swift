import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped courier exception must pass. Check returns its problems, or none.
    protocol CappedCourierExceptionRule {
        func check(_ item: CappedCourierException) -> [String]
    }

    final class CappedCourierExceptionCopayRangeRule: CappedCourierExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCourierException) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedCourierExceptionCodePrefixRule: CappedCourierExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedCourierException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedCourierExceptionRequiredBedRule: CappedCourierExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCourierException) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped courier exception.
    final class CappedCourierExceptionValidator {
        var rules: [any CappedCourierExceptionRule]

        init(rules: [any CappedCourierExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCourierException) -> [String] {
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

        func requireValid(_ item: CappedCourierException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCourierException]) -> [String: [String]] {
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

    static func defaultCappedCourierExceptionValidator() -> CappedCourierExceptionValidator {
        return CappedCourierExceptionValidator(
            rules: [
                CappedCourierExceptionCopayRangeRule(min: 6.1, max: 4465.3),
                CappedCourierExceptionCodePrefixRule(prefix: "ACM"),
                CappedCourierExceptionRequiredBedRule(message: "capped courier exception needs an entry"),
            ]
        )
    }
}
