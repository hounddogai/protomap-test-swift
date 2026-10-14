import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census summary must pass. Check returns its problems, or none.
    protocol CensusSummaryRule {
        func check(_ item: CensusSummary) -> [String]
    }

    final class CensusSummaryRequiredAllergyRule: CensusSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusSummary) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusSummaryRequiredLabelRule: CensusSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusSummaryAllergyLengthRule: CensusSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusSummary) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusSummaryLabelLengthRule: CensusSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a census summary.
    final class CensusSummaryValidator {
        var rules: [any CensusSummaryRule]

        init(rules: [any CensusSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusSummary]) -> [String: [String]] {
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

    static func defaultCensusSummaryValidator() -> CensusSummaryValidator {
        return CensusSummaryValidator(
            rules: [
                CensusSummaryRequiredAllergyRule(message: "census summary needs this field"),
                CensusSummaryRequiredLabelRule(message: "census summary needs a value"),
                CensusSummaryAllergyLengthRule(maxLength: 32),
                CensusSummaryLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
