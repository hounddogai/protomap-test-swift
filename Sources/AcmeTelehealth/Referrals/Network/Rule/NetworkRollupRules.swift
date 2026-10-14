import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network rollup must pass. Check returns its problems, or none.
    protocol NetworkRollupRule {
        func check(_ item: NetworkRollup) -> [String]
    }

    final class NetworkRollupReviewerLengthRule: NetworkRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkRollup) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkRollupCodePrefixRule: NetworkRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: NetworkRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class NetworkRollupRequiredNameRule: NetworkRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkRollupEndsAtRangeRule: NetworkRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkRollup) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a network rollup.
    final class NetworkRollupValidator {
        var rules: [any NetworkRollupRule]

        init(rules: [any NetworkRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkRollup]) -> [String: [String]] {
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

    static func defaultNetworkRollupValidator() -> NetworkRollupValidator {
        return NetworkRollupValidator(
            rules: [
                NetworkRollupReviewerLengthRule(maxLength: 120),
                NetworkRollupCodePrefixRule(prefix: "ACM"),
                NetworkRollupRequiredNameRule(message: "network rollup needs an entry"),
                NetworkRollupEndsAtRangeRule(min: 64, max: 64),
            ]
        )
    }
}
