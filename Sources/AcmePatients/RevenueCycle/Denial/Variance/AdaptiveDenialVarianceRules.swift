import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive denial variance must pass. Check returns its problems, or none.
    protocol AdaptiveDenialVarianceRule {
        func check(_ item: AdaptiveDenialVariance) -> [String]
    }

    final class AdaptiveDenialVarianceLabelLengthRule: AdaptiveDenialVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDenialVariance) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveDenialVarianceApprovedGuardRule: AdaptiveDenialVarianceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: AdaptiveDenialVariance) -> [String] {
            if item.approved && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class AdaptiveDenialVarianceRequiredCodeRule: AdaptiveDenialVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDenialVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive denial variance.
    final class AdaptiveDenialVarianceValidator {
        var rules: [any AdaptiveDenialVarianceRule]

        init(rules: [any AdaptiveDenialVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveDenialVariance) -> [String] {
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

        func requireValid(_ item: AdaptiveDenialVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveDenialVariance]) -> [String: [String]] {
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

    static func defaultAdaptiveDenialVarianceValidator() -> AdaptiveDenialVarianceValidator {
        return AdaptiveDenialVarianceValidator(
            rules: [
                AdaptiveDenialVarianceLabelLengthRule(maxLength: 32),
                AdaptiveDenialVarianceApprovedGuardRule(limit: 7.6),
                AdaptiveDenialVarianceRequiredCodeRule(message: "adaptive denial variance needs a value"),
            ]
        )
    }
}
