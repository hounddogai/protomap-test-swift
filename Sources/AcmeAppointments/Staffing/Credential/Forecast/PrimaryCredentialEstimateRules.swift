import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary credential estimate must pass. Check returns its problems, or none.
    protocol PrimaryCredentialEstimateRule {
        func check(_ item: PrimaryCredentialEstimate) -> [String]
    }

    final class PrimaryCredentialEstimateRateRangeRule: PrimaryCredentialEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCredentialEstimate) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryCredentialEstimateRequiredUnitRule: PrimaryCredentialEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCredentialEstimate) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCredentialEstimateExternalRefLengthRule: PrimaryCredentialEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCredentialEstimate) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary credential estimate.
    final class PrimaryCredentialEstimateValidator {
        var rules: [any PrimaryCredentialEstimateRule]

        init(rules: [any PrimaryCredentialEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCredentialEstimate) -> [String] {
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

        func requireValid(_ item: PrimaryCredentialEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCredentialEstimate]) -> [String: [String]] {
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

    static func defaultPrimaryCredentialEstimateValidator() -> PrimaryCredentialEstimateValidator {
        return PrimaryCredentialEstimateValidator(
            rules: [
                PrimaryCredentialEstimateRateRangeRule(min: 9.5, max: 1367.8),
                PrimaryCredentialEstimateRequiredUnitRule(message: "primary credential estimate needs an entry"),
                PrimaryCredentialEstimateExternalRefLengthRule(maxLength: 64),
            ]
        )
    }
}
