import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary order set estimate must pass. Check returns its problems, or none.
    protocol PrimaryOrderSetEstimateRule {
        func check(_ item: PrimaryOrderSetEstimate) -> [String]
    }

    final class PrimaryOrderSetEstimatePatientRefLengthRule: PrimaryOrderSetEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOrderSetEstimate) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOrderSetEstimateRequiredCodeRule: PrimaryOrderSetEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOrderSetEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOrderSetEstimateCodePrefixRule: PrimaryOrderSetEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryOrderSetEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryOrderSetEstimateContactEmailLengthRule: PrimaryOrderSetEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOrderSetEstimate) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOrderSetEstimateLimitRangeRule: PrimaryOrderSetEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOrderSetEstimate) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary order set estimate.
    final class PrimaryOrderSetEstimateValidator {
        var rules: [any PrimaryOrderSetEstimateRule]

        init(rules: [any PrimaryOrderSetEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOrderSetEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryOrderSetEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOrderSetEstimate]) -> [String: [String]] {
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

    static func defaultPrimaryOrderSetEstimateValidator() -> PrimaryOrderSetEstimateValidator {
        return PrimaryOrderSetEstimateValidator(
            rules: [
                PrimaryOrderSetEstimatePatientRefLengthRule(maxLength: 86400),
                PrimaryOrderSetEstimateRequiredCodeRule(message: "primary order set estimate needs a value"),
                PrimaryOrderSetEstimateCodePrefixRule(prefix: "OPS"),
                PrimaryOrderSetEstimateContactEmailLengthRule(maxLength: 32),
                PrimaryOrderSetEstimateLimitRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
