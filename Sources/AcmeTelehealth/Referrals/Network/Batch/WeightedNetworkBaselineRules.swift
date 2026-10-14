import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted network baseline must pass. Check returns its problems, or none.
    protocol WeightedNetworkBaselineRule {
        func check(_ item: WeightedNetworkBaseline) -> [String]
    }

    final class WeightedNetworkBaselineTitleLengthRule: WeightedNetworkBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedNetworkBaseline) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedNetworkBaselineRequiredNameRule: WeightedNetworkBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedNetworkBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedNetworkBaselineApprovedGuardRule: WeightedNetworkBaselineRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WeightedNetworkBaseline) -> [String] {
            if item.approved && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class WeightedNetworkBaselineCodePrefixRule: WeightedNetworkBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedNetworkBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted network baseline.
    final class WeightedNetworkBaselineValidator {
        var rules: [any WeightedNetworkBaselineRule]

        init(rules: [any WeightedNetworkBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedNetworkBaseline) -> [String] {
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

        func requireValid(_ item: WeightedNetworkBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedNetworkBaseline]) -> [String: [String]] {
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

    static func defaultWeightedNetworkBaselineValidator() -> WeightedNetworkBaselineValidator {
        return WeightedNetworkBaselineValidator(
            rules: [
                WeightedNetworkBaselineTitleLengthRule(maxLength: 120),
                WeightedNetworkBaselineRequiredNameRule(message: "weighted network baseline needs this field"),
                WeightedNetworkBaselineApprovedGuardRule(limit: 64),
                WeightedNetworkBaselineCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
