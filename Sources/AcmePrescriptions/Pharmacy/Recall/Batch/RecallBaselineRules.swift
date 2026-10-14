import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall baseline must pass. Check returns its problems, or none.
    protocol RecallBaselineRule {
        func check(_ item: RecallBaseline) -> [String]
    }

    final class RecallBaselineMaximumRangeRule: RecallBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallBaseline) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RecallBaselineRequiredChecksumRule: RecallBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallBaseline) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallBaselineRequiredPhoneRule: RecallBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallBaseline) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall baseline.
    final class RecallBaselineValidator {
        var rules: [any RecallBaselineRule]

        init(rules: [any RecallBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallBaseline) -> [String] {
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

        func requireValid(_ item: RecallBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallBaseline]) -> [String: [String]] {
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

    static func defaultRecallBaselineValidator() -> RecallBaselineValidator {
        return RecallBaselineValidator(
            rules: [
                RecallBaselineMaximumRangeRule(min: 3.5, max: 4528.7),
                RecallBaselineRequiredChecksumRule(message: "recall baseline needs this field"),
                RecallBaselineRequiredPhoneRule(message: "recall baseline needs this field"),
            ]
        )
    }
}
