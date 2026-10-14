import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense metric must pass. Check returns its problems, or none.
    protocol DispenseMetricRule {
        func check(_ item: DispenseMetric) -> [String]
    }

    final class DispenseMetricCodeLengthRule: DispenseMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseMetricNotesLengthRule: DispenseMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseMetric) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseMetricPhoneLengthRule: DispenseMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseMetric) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense metric.
    final class DispenseMetricValidator {
        var rules: [any DispenseMetricRule]

        init(rules: [any DispenseMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseMetric) -> [String] {
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

        func requireValid(_ item: DispenseMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseMetric]) -> [String: [String]] {
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

    static func defaultDispenseMetricValidator() -> DispenseMetricValidator {
        return DispenseMetricValidator(
            rules: [
                DispenseMetricCodeLengthRule(maxLength: 120),
                DispenseMetricNotesLengthRule(maxLength: 3600),
                DispenseMetricPhoneLengthRule(maxLength: 32),
            ]
        )
    }
}
