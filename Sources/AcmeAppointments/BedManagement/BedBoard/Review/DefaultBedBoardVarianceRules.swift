import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default bed board variance must pass. Check returns its problems, or none.
    protocol DefaultBedBoardVarianceRule {
        func check(_ item: DefaultBedBoardVariance) -> [String]
    }

    final class DefaultBedBoardVarianceRequiredCodeRule: DefaultBedBoardVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultBedBoardVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultBedBoardVarianceDurationMinutesRangeRule: DefaultBedBoardVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultBedBoardVariance) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultBedBoardVarianceCodePrefixRule: DefaultBedBoardVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultBedBoardVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a default bed board variance.
    final class DefaultBedBoardVarianceValidator {
        var rules: [any DefaultBedBoardVarianceRule]

        init(rules: [any DefaultBedBoardVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultBedBoardVariance) -> [String] {
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

        func requireValid(_ item: DefaultBedBoardVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultBedBoardVariance]) -> [String: [String]] {
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

    static func defaultDefaultBedBoardVarianceValidator() -> DefaultBedBoardVarianceValidator {
        return DefaultBedBoardVarianceValidator(
            rules: [
                DefaultBedBoardVarianceRequiredCodeRule(message: "default bed board variance needs this field"),
                DefaultBedBoardVarianceDurationMinutesRangeRule(min: 255, max: 3600),
                DefaultBedBoardVarianceCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
