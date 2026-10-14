import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense estimate must pass. Check returns its problems, or none.
    protocol DispenseEstimateRule {
        func check(_ item: DispenseEstimate) -> [String]
    }

    final class DispenseEstimateRequiredCodeRule: DispenseEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseEstimateRequiredContactEmailRule: DispenseEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseEstimate) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseEstimateQuantityRangeRule: DispenseEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseEstimate) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseEstimateRequiredPatientRefRule: DispenseEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseEstimate) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseEstimatePatientRefLengthRule: DispenseEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseEstimate) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense estimate.
    final class DispenseEstimateValidator {
        var rules: [any DispenseEstimateRule]

        init(rules: [any DispenseEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseEstimate]) -> [String: [String]] {
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

    static func defaultDispenseEstimateValidator() -> DispenseEstimateValidator {
        return DispenseEstimateValidator(
            rules: [
                DispenseEstimateRequiredCodeRule(message: "dispense estimate needs this field"),
                DispenseEstimateRequiredContactEmailRule(message: "dispense estimate needs an entry"),
                DispenseEstimateQuantityRangeRule(min: 120, max: 3600),
                DispenseEstimateRequiredPatientRefRule(message: "dispense estimate needs this field"),
                DispenseEstimatePatientRefLengthRule(maxLength: 32),
            ]
        )
    }
}
