import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive handoff variance must pass. Check returns its problems, or none.
    protocol AdaptiveHandoffVarianceRule {
        func check(_ item: AdaptiveHandoffVariance) -> [String]
    }

    final class AdaptiveHandoffVarianceOwnerIDLengthRule: AdaptiveHandoffVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveHandoffVariance) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveHandoffVarianceRequiredLabelRule: AdaptiveHandoffVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveHandoffVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveHandoffVarianceStartsAtRangeRule: AdaptiveHandoffVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveHandoffVariance) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveHandoffVarianceLabelLengthRule: AdaptiveHandoffVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveHandoffVariance) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveHandoffVarianceRequiredOwnerIDRule: AdaptiveHandoffVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveHandoffVariance) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive handoff variance.
    final class AdaptiveHandoffVarianceValidator {
        var rules: [any AdaptiveHandoffVarianceRule]

        init(rules: [any AdaptiveHandoffVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveHandoffVariance) -> [String] {
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

        func requireValid(_ item: AdaptiveHandoffVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveHandoffVariance]) -> [String: [String]] {
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

    static func defaultAdaptiveHandoffVarianceValidator() -> AdaptiveHandoffVarianceValidator {
        return AdaptiveHandoffVarianceValidator(
            rules: [
                AdaptiveHandoffVarianceOwnerIDLengthRule(maxLength: 32),
                AdaptiveHandoffVarianceRequiredLabelRule(message: "adaptive handoff variance needs an entry"),
                AdaptiveHandoffVarianceStartsAtRangeRule(min: 64, max: 120),
                AdaptiveHandoffVarianceLabelLengthRule(maxLength: 1000),
                AdaptiveHandoffVarianceRequiredOwnerIDRule(message: "adaptive handoff variance needs an entry"),
            ]
        )
    }
}
