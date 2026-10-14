import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive network cycle must pass. Check returns its problems, or none.
    protocol AdaptiveNetworkCycleRule {
        func check(_ item: AdaptiveNetworkCycle) -> [String]
    }

    final class AdaptiveNetworkCycleAllergyLengthRule: AdaptiveNetworkCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveNetworkCycle) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveNetworkCycleCodeLengthRule: AdaptiveNetworkCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveNetworkCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveNetworkCycleCodePrefixRule: AdaptiveNetworkCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveNetworkCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveNetworkCycleRequiredLabelRule: AdaptiveNetworkCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveNetworkCycle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveNetworkCycleAllowedAllergyRule: AdaptiveNetworkCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveNetworkCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive network cycle.
    final class AdaptiveNetworkCycleValidator {
        var rules: [any AdaptiveNetworkCycleRule]

        init(rules: [any AdaptiveNetworkCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveNetworkCycle) -> [String] {
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

        func requireValid(_ item: AdaptiveNetworkCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveNetworkCycle]) -> [String: [String]] {
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

    static func defaultAdaptiveNetworkCycleValidator() -> AdaptiveNetworkCycleValidator {
        return AdaptiveNetworkCycleValidator(
            rules: [
                AdaptiveNetworkCycleAllergyLengthRule(maxLength: 86400),
                AdaptiveNetworkCycleCodeLengthRule(maxLength: 64),
                AdaptiveNetworkCycleCodePrefixRule(prefix: "ACM"),
                AdaptiveNetworkCycleRequiredLabelRule(message: "adaptive network cycle needs this field"),
                AdaptiveNetworkCycleAllowedAllergyRule(allowed: []),
            ]
        )
    }
}
