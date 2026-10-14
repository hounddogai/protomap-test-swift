import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual claim estimate must pass. Check returns its problems, or none.
    protocol ManualClaimEstimateRule {
        func check(_ item: ManualClaimEstimate) -> [String]
    }

    final class ManualClaimEstimateCapacityRangeRule: ManualClaimEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualClaimEstimate) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualClaimEstimateRequiredNameRule: ManualClaimEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualClaimEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualClaimEstimateNameLengthRule: ManualClaimEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClaimEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualClaimEstimateReviewerLengthRule: ManualClaimEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClaimEstimate) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualClaimEstimateCodePrefixRule: ManualClaimEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualClaimEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual claim estimate.
    final class ManualClaimEstimateValidator {
        var rules: [any ManualClaimEstimateRule]

        init(rules: [any ManualClaimEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualClaimEstimate) -> [String] {
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

        func requireValid(_ item: ManualClaimEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualClaimEstimate]) -> [String: [String]] {
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

    static func defaultManualClaimEstimateValidator() -> ManualClaimEstimateValidator {
        return ManualClaimEstimateValidator(
            rules: [
                ManualClaimEstimateCapacityRangeRule(min: 32, max: 255),
                ManualClaimEstimateRequiredNameRule(message: "manual claim estimate needs this field"),
                ManualClaimEstimateNameLengthRule(maxLength: 32),
                ManualClaimEstimateReviewerLengthRule(maxLength: 64),
                ManualClaimEstimateCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
