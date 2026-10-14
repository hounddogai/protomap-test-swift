import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient census tier must pass. Check returns its problems, or none.
    protocol LenientCensusTierRule {
        func check(_ item: LenientCensusTier) -> [String]
    }

    final class LenientCensusTierGraceDaysRangeRule: LenientCensusTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCensusTier) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientCensusTierRequiredCodeRule: LenientCensusTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCensusTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCensusTierRequiredTitleRule: LenientCensusTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCensusTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient census tier.
    final class LenientCensusTierValidator {
        var rules: [any LenientCensusTierRule]

        init(rules: [any LenientCensusTierRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCensusTier) -> [String] {
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

        func requireValid(_ item: LenientCensusTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCensusTier]) -> [String: [String]] {
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

    static func defaultLenientCensusTierValidator() -> LenientCensusTierValidator {
        return LenientCensusTierValidator(
            rules: [
                LenientCensusTierGraceDaysRangeRule(min: 80, max: 86400),
                LenientCensusTierRequiredCodeRule(message: "lenient census tier needs a value"),
                LenientCensusTierRequiredTitleRule(message: "lenient census tier needs an entry"),
            ]
        )
    }
}
