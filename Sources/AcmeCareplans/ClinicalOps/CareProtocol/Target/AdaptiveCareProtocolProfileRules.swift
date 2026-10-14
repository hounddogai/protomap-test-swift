import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive care protocol profile must pass. Check returns its problems, or none.
    protocol AdaptiveCareProtocolProfileRule {
        func check(_ item: AdaptiveCareProtocolProfile) -> [String]
    }

    final class AdaptiveCareProtocolProfileRequiredTitleRule: AdaptiveCareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCareProtocolProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolProfileDosageMgRangeRule: AdaptiveCareProtocolProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCareProtocolProfile) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolProfileCodePrefixRule: AdaptiveCareProtocolProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveCareProtocolProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive care protocol profile.
    final class AdaptiveCareProtocolProfileValidator {
        var rules: [any AdaptiveCareProtocolProfileRule]

        init(rules: [any AdaptiveCareProtocolProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCareProtocolProfile) -> [String] {
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

        func requireValid(_ item: AdaptiveCareProtocolProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCareProtocolProfile]) -> [String: [String]] {
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

    static func defaultAdaptiveCareProtocolProfileValidator() -> AdaptiveCareProtocolProfileValidator {
        return AdaptiveCareProtocolProfileValidator(
            rules: [
                AdaptiveCareProtocolProfileRequiredTitleRule(
                    message: "adaptive care protocol profile needs this field"
                ),
                AdaptiveCareProtocolProfileDosageMgRangeRule(min: 9.4, max: 2676.6),
                AdaptiveCareProtocolProfileCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
