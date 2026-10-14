import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen metric must pass. Check returns its problems, or none.
    protocol SpecimenMetricRule {
        func check(_ item: SpecimenMetric) -> [String]
    }

    final class SpecimenMetricRequiredTitleRule: SpecimenMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenMetricRequiredCodeRule: SpecimenMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenMetricRequiredOwnerIDRule: SpecimenMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenMetric) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenMetricTitleLengthRule: SpecimenMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenMetricOwnerIDLengthRule: SpecimenMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenMetric) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen metric.
    final class SpecimenMetricValidator {
        var rules: [any SpecimenMetricRule]

        init(rules: [any SpecimenMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenMetric) -> [String] {
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

        func requireValid(_ item: SpecimenMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenMetric]) -> [String: [String]] {
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

    static func defaultSpecimenMetricValidator() -> SpecimenMetricValidator {
        return SpecimenMetricValidator(
            rules: [
                SpecimenMetricRequiredTitleRule(message: "specimen metric needs this field"),
                SpecimenMetricRequiredCodeRule(message: "specimen metric needs a value"),
                SpecimenMetricRequiredOwnerIDRule(message: "specimen metric needs a value"),
                SpecimenMetricTitleLengthRule(maxLength: 16),
                SpecimenMetricOwnerIDLengthRule(maxLength: 80),
            ]
        )
    }
}
