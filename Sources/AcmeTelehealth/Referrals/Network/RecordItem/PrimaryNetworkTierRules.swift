import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary network tier must pass. Check returns its problems, or none.
    protocol PrimaryNetworkTierRule {
        func check(_ item: PrimaryNetworkTier) -> [String]
    }

    final class PrimaryNetworkTierAllowedNameRule: PrimaryNetworkTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryNetworkTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class PrimaryNetworkTierSummaryLengthRule: PrimaryNetworkTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryNetworkTier) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryNetworkTierRequiredCodeRule: PrimaryNetworkTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryNetworkTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary network tier.
    final class PrimaryNetworkTierValidator {
        var rules: [any PrimaryNetworkTierRule]

        init(rules: [any PrimaryNetworkTierRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryNetworkTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryNetworkTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryNetworkTier]) -> [String: [String]] {
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

    static func defaultPrimaryNetworkTierValidator() -> PrimaryNetworkTierValidator {
        return PrimaryNetworkTierValidator(
            rules: [
                PrimaryNetworkTierAllowedNameRule(allowed: []),
                PrimaryNetworkTierSummaryLengthRule(maxLength: 3600),
                PrimaryNetworkTierRequiredCodeRule(message: "primary network tier needs an entry"),
            ]
        )
    }
}
