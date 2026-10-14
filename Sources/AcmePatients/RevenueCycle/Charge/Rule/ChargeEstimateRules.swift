import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge estimate must pass. Check returns its problems, or none.
    protocol ChargeEstimateRule {
        func check(_ item: ChargeEstimate) -> [String]
    }

    final class ChargeEstimateRequiredNameRule: ChargeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeEstimateCodeLengthRule: ChargeEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeEstimateNameLengthRule: ChargeEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge estimate.
    final class ChargeEstimateValidator {
        var rules: [any ChargeEstimateRule]

        init(rules: [any ChargeEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeEstimate) -> [String] {
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

        func requireValid(_ item: ChargeEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeEstimate]) -> [String: [String]] {
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

    static func defaultChargeEstimateValidator() -> ChargeEstimateValidator {
        return ChargeEstimateValidator(
            rules: [
                ChargeEstimateRequiredNameRule(message: "charge estimate needs this field"),
                ChargeEstimateCodeLengthRule(maxLength: 255),
                ChargeEstimateNameLengthRule(maxLength: 255),
            ]
        )
    }
}
