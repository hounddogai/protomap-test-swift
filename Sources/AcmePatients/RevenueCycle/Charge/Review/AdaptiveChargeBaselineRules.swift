import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive charge baseline must pass. Check returns its problems, or none.
    protocol AdaptiveChargeBaselineRule {
        func check(_ item: AdaptiveChargeBaseline) -> [String]
    }

    final class AdaptiveChargeBaselineRequiredNameRule: AdaptiveChargeBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveChargeBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveChargeBaselineClinicianIDLengthRule: AdaptiveChargeBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveChargeBaseline) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveChargeBaselineQuantityRangeRule: AdaptiveChargeBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveChargeBaseline) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveChargeBaselineDescriptionLengthRule: AdaptiveChargeBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveChargeBaseline) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive charge baseline.
    final class AdaptiveChargeBaselineValidator {
        var rules: [any AdaptiveChargeBaselineRule]

        init(rules: [any AdaptiveChargeBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveChargeBaseline) -> [String] {
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

        func requireValid(_ item: AdaptiveChargeBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveChargeBaseline]) -> [String: [String]] {
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

    static func defaultAdaptiveChargeBaselineValidator() -> AdaptiveChargeBaselineValidator {
        return AdaptiveChargeBaselineValidator(
            rules: [
                AdaptiveChargeBaselineRequiredNameRule(message: "adaptive charge baseline needs an entry"),
                AdaptiveChargeBaselineClinicianIDLengthRule(maxLength: 64),
                AdaptiveChargeBaselineQuantityRangeRule(min: 32, max: 3600),
                AdaptiveChargeBaselineDescriptionLengthRule(maxLength: 255),
            ]
        )
    }
}
