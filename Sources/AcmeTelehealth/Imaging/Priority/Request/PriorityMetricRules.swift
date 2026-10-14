import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority metric must pass. Check returns its problems, or none.
    protocol PriorityMetricRule {
        func check(_ item: PriorityMetric) -> [String]
    }

    final class PriorityMetricSpecialtyLengthRule: PriorityMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityMetric) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityMetricTitleLengthRule: PriorityMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityMetricAllergyLengthRule: PriorityMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityMetric) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority metric.
    final class PriorityMetricValidator {
        var rules: [any PriorityMetricRule]

        init(rules: [any PriorityMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityMetric) -> [String] {
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

        func requireValid(_ item: PriorityMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityMetric]) -> [String: [String]] {
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

    static func defaultPriorityMetricValidator() -> PriorityMetricValidator {
        return PriorityMetricValidator(
            rules: [
                PriorityMetricSpecialtyLengthRule(maxLength: 120),
                PriorityMetricTitleLengthRule(maxLength: 3600),
                PriorityMetricAllergyLengthRule(maxLength: 255),
            ]
        )
    }
}
