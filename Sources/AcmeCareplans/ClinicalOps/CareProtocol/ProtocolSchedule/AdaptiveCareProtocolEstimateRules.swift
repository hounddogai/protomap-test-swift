import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive care protocol estimate must pass. Check returns its problems, or none.
    protocol AdaptiveCareProtocolEstimateRule {
        func check(_ item: AdaptiveCareProtocolEstimate) -> [String]
    }

    final class AdaptiveCareProtocolEstimateAcuityRangeRule: AdaptiveCareProtocolEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCareProtocolEstimate) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolEstimateRequiredPatientRefRule: AdaptiveCareProtocolEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCareProtocolEstimate) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolEstimatePatientRefLengthRule: AdaptiveCareProtocolEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareProtocolEstimate) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolEstimateCodePrefixRule: AdaptiveCareProtocolEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveCareProtocolEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolEstimateCodeLengthRule: AdaptiveCareProtocolEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareProtocolEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive care protocol estimate.
    final class AdaptiveCareProtocolEstimateValidator {
        var rules: [any AdaptiveCareProtocolEstimateRule]

        init(rules: [any AdaptiveCareProtocolEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCareProtocolEstimate) -> [String] {
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

        func requireValid(_ item: AdaptiveCareProtocolEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCareProtocolEstimate]) -> [String: [String]] {
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

    static func defaultAdaptiveCareProtocolEstimateValidator() -> AdaptiveCareProtocolEstimateValidator {
        return AdaptiveCareProtocolEstimateValidator(
            rules: [
                AdaptiveCareProtocolEstimateAcuityRangeRule(min: 3600, max: 86400),
                AdaptiveCareProtocolEstimateRequiredPatientRefRule(
                    message: "adaptive care protocol estimate needs a value"
                ),
                AdaptiveCareProtocolEstimatePatientRefLengthRule(maxLength: 120),
                AdaptiveCareProtocolEstimateCodePrefixRule(prefix: "REF"),
                AdaptiveCareProtocolEstimateCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
