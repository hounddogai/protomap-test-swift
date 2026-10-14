import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach variance must pass. Check returns its problems, or none.
    protocol OutreachVarianceRule {
        func check(_ item: OutreachVariance) -> [String]
    }

    final class OutreachVarianceQuantityRangeRule: OutreachVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachVariance) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OutreachVarianceNotesLengthRule: OutreachVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachVariance) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachVarianceGraceDaysRangeRule: OutreachVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachVariance) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach variance.
    final class OutreachVarianceValidator {
        var rules: [any OutreachVarianceRule]

        init(rules: [any OutreachVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachVariance) -> [String] {
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

        func requireValid(_ item: OutreachVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachVariance]) -> [String: [String]] {
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

    static func defaultOutreachVarianceValidator() -> OutreachVarianceValidator {
        return OutreachVarianceValidator(
            rules: [
                OutreachVarianceQuantityRangeRule(min: 255, max: 86400),
                OutreachVarianceNotesLengthRule(maxLength: 255),
                OutreachVarianceGraceDaysRangeRule(min: 16, max: 80),
            ]
        )
    }
}
