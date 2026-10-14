import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary disclosure summary must pass. Check returns its problems, or none.
    protocol PrimaryDisclosureSummaryRule {
        func check(_ item: PrimaryDisclosureSummary) -> [String]
    }

    final class PrimaryDisclosureSummaryRequiredPatientRefRule: PrimaryDisclosureSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDisclosureSummary) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDisclosureSummaryRegionLengthRule: PrimaryDisclosureSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDisclosureSummary) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDisclosureSummaryCopayRangeRule: PrimaryDisclosureSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDisclosureSummary) -> [String] {
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

    final class PrimaryDisclosureSummaryNameLengthRule: PrimaryDisclosureSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDisclosureSummary) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDisclosureSummaryQuantityRangeRule: PrimaryDisclosureSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDisclosureSummary) -> [String] {
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

    /// Runs every rule of a primary disclosure summary.
    final class PrimaryDisclosureSummaryValidator {
        var rules: [any PrimaryDisclosureSummaryRule]

        init(rules: [any PrimaryDisclosureSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDisclosureSummary) -> [String] {
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

        func requireValid(_ item: PrimaryDisclosureSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDisclosureSummary]) -> [String: [String]] {
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

    static func defaultPrimaryDisclosureSummaryValidator() -> PrimaryDisclosureSummaryValidator {
        return PrimaryDisclosureSummaryValidator(
            rules: [
                PrimaryDisclosureSummaryRequiredPatientRefRule(message: "primary disclosure summary needs this field"),
                PrimaryDisclosureSummaryRegionLengthRule(maxLength: 86400),
                PrimaryDisclosureSummaryCopayRangeRule(min: 0.5, max: 2814.7),
                PrimaryDisclosureSummaryNameLengthRule(maxLength: 32),
                PrimaryDisclosureSummaryQuantityRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
