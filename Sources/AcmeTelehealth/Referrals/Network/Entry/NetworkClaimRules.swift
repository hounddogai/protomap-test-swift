import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network claim must pass. Check returns its problems, or none.
    protocol NetworkClaimRule {
        func check(_ item: NetworkClaim) -> [String]
    }

    final class NetworkClaimExpiresAtRangeRule: NetworkClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkClaim) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkClaimCodeLengthRule: NetworkClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkClaimTitleLengthRule: NetworkClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network claim.
    final class NetworkClaimValidator {
        var rules: [any NetworkClaimRule]

        init(rules: [any NetworkClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkClaim]) -> [String: [String]] {
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

    static func defaultNetworkClaimValidator() -> NetworkClaimValidator {
        return NetworkClaimValidator(
            rules: [
                NetworkClaimExpiresAtRangeRule(min: 64, max: 120),
                NetworkClaimCodeLengthRule(maxLength: 120),
                NetworkClaimTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
