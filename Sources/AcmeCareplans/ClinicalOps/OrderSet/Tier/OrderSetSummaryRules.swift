import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set summary must pass. Check returns its problems, or none.
    protocol OrderSetSummaryRule {
        func check(_ item: OrderSetSummary) -> [String]
    }

    final class OrderSetSummarySegmentLengthRule: OrderSetSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetSummary) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetSummaryRequiredPatientRefRule: OrderSetSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetSummary) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetSummaryPatientRefLengthRule: OrderSetSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetSummary) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetSummaryEndsAtRangeRule: OrderSetSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetSummary) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetSummaryRetriesRangeRule: OrderSetSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetSummary) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a order set summary.
    final class OrderSetSummaryValidator {
        var rules: [any OrderSetSummaryRule]

        init(rules: [any OrderSetSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetSummary) -> [String] {
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

        func requireValid(_ item: OrderSetSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetSummary]) -> [String: [String]] {
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

    static func defaultOrderSetSummaryValidator() -> OrderSetSummaryValidator {
        return OrderSetSummaryValidator(
            rules: [
                OrderSetSummarySegmentLengthRule(maxLength: 16),
                OrderSetSummaryRequiredPatientRefRule(message: "order set summary needs an entry"),
                OrderSetSummaryPatientRefLengthRule(maxLength: 80),
                OrderSetSummaryEndsAtRangeRule(min: 16, max: 80),
                OrderSetSummaryRetriesRangeRule(min: 32, max: 3600),
            ]
        )
    }
}
