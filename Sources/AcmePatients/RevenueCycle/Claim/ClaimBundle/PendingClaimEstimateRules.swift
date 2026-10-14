import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending claim estimate must pass. Check returns its problems, or none.
    protocol PendingClaimEstimateRule {
        func check(_ item: PendingClaimEstimate) -> [String]
    }

    final class PendingClaimEstimateAllowedCodeRule: PendingClaimEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingClaimEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class PendingClaimEstimateCopayRangeRule: PendingClaimEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingClaimEstimate) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingClaimEstimateCodeLengthRule: PendingClaimEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingClaimEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingClaimEstimateRequiredLabelRule: PendingClaimEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingClaimEstimate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingClaimEstimateRequiredWardRule: PendingClaimEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingClaimEstimate) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending claim estimate.
    final class PendingClaimEstimateValidator {
        var rules: [any PendingClaimEstimateRule]

        init(rules: [any PendingClaimEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingClaimEstimate) -> [String] {
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

        func requireValid(_ item: PendingClaimEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingClaimEstimate]) -> [String: [String]] {
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

    static func defaultPendingClaimEstimateValidator() -> PendingClaimEstimateValidator {
        return PendingClaimEstimateValidator(
            rules: [
                PendingClaimEstimateAllowedCodeRule(allowed: ["tiered", "tiered"]),
                PendingClaimEstimateCopayRangeRule(min: 0.2, max: 4333.1),
                PendingClaimEstimateCodeLengthRule(maxLength: 64),
                PendingClaimEstimateRequiredLabelRule(message: "pending claim estimate needs this field"),
                PendingClaimEstimateRequiredWardRule(message: "pending claim estimate needs an entry"),
            ]
        )
    }
}
