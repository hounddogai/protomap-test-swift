import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback transfer plan must pass. Check returns its problems, or none.
    protocol FallbackTransferPlanRule {
        func check(_ item: FallbackTransferPlan) -> [String]
    }

    final class FallbackTransferPlanPatientRefLengthRule: FallbackTransferPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackTransferPlan) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackTransferPlanRequiredChecksumRule: FallbackTransferPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackTransferPlan) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackTransferPlanCodePrefixRule: FallbackTransferPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackTransferPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackTransferPlanRequiredLabelRule: FallbackTransferPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackTransferPlan) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackTransferPlanCopayRangeRule: FallbackTransferPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackTransferPlan) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback transfer plan.
    final class FallbackTransferPlanValidator {
        var rules: [any FallbackTransferPlanRule]

        init(rules: [any FallbackTransferPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackTransferPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackTransferPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackTransferPlan]) -> [String: [String]] {
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

    static func defaultFallbackTransferPlanValidator() -> FallbackTransferPlanValidator {
        return FallbackTransferPlanValidator(
            rules: [
                FallbackTransferPlanPatientRefLengthRule(maxLength: 120),
                FallbackTransferPlanRequiredChecksumRule(message: "fallback transfer plan needs an entry"),
                FallbackTransferPlanCodePrefixRule(prefix: "ACM"),
                FallbackTransferPlanRequiredLabelRule(message: "fallback transfer plan needs an entry"),
                FallbackTransferPlanCopayRangeRule(min: 0.5, max: 1578.0),
            ]
        )
    }
}
