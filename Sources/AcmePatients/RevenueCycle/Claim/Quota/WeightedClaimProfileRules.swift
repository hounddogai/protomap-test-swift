import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted claim profile must pass. Check returns its problems, or none.
    protocol WeightedClaimProfileRule {
        func check(_ item: WeightedClaimProfile) -> [String]
    }

    final class WeightedClaimProfileCopayRangeRule: WeightedClaimProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedClaimProfile) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedClaimProfileCodePrefixRule: WeightedClaimProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedClaimProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedClaimProfileRequiredChecksumRule: WeightedClaimProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedClaimProfile) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedClaimProfileArchivedGuardRule: WeightedClaimProfileRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: WeightedClaimProfile) -> [String] {
            if item.archived && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted claim profile.
    final class WeightedClaimProfileValidator {
        var rules: [any WeightedClaimProfileRule]

        init(rules: [any WeightedClaimProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedClaimProfile) -> [String] {
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

        func requireValid(_ item: WeightedClaimProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedClaimProfile]) -> [String: [String]] {
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

    static func defaultWeightedClaimProfileValidator() -> WeightedClaimProfileValidator {
        return WeightedClaimProfileValidator(
            rules: [
                WeightedClaimProfileCopayRangeRule(min: 1.2, max: 1906.0),
                WeightedClaimProfileCodePrefixRule(prefix: "ACM"),
                WeightedClaimProfileRequiredChecksumRule(message: "weighted claim profile needs a value"),
                WeightedClaimProfileArchivedGuardRule(limit: 3.9),
            ]
        )
    }
}
