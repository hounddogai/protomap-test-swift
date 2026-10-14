import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered network digest must pass. Check returns its problems, or none.
    protocol TieredNetworkDigestRule {
        func check(_ item: TieredNetworkDigest) -> [String]
    }

    final class TieredNetworkDigestCodePrefixRule: TieredNetworkDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredNetworkDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredNetworkDigestStartsAtRangeRule: TieredNetworkDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredNetworkDigest) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredNetworkDigestRequiredChannelRule: TieredNetworkDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredNetworkDigest) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered network digest.
    final class TieredNetworkDigestValidator {
        var rules: [any TieredNetworkDigestRule]

        init(rules: [any TieredNetworkDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredNetworkDigest) -> [String] {
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

        func requireValid(_ item: TieredNetworkDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredNetworkDigest]) -> [String: [String]] {
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

    static func defaultTieredNetworkDigestValidator() -> TieredNetworkDigestValidator {
        return TieredNetworkDigestValidator(
            rules: [
                TieredNetworkDigestCodePrefixRule(prefix: "Q"),
                TieredNetworkDigestStartsAtRangeRule(min: 120, max: 3600),
                TieredNetworkDigestRequiredChannelRule(message: "tiered network digest needs an entry"),
            ]
        )
    }
}
