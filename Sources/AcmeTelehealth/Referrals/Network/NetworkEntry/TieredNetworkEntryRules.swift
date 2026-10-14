import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered network entry must pass. Check returns its problems, or none.
    protocol TieredNetworkEntryRule {
        func check(_ item: TieredNetworkEntry) -> [String]
    }

    final class TieredNetworkEntryLocaleLengthRule: TieredNetworkEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredNetworkEntry) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredNetworkEntryAttemptsRangeRule: TieredNetworkEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredNetworkEntry) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredNetworkEntryRequiredTitleRule: TieredNetworkEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredNetworkEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredNetworkEntryRequiredLocaleRule: TieredNetworkEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredNetworkEntry) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered network entry.
    final class TieredNetworkEntryValidator {
        var rules: [any TieredNetworkEntryRule]

        init(rules: [any TieredNetworkEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredNetworkEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredNetworkEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredNetworkEntry]) -> [String: [String]] {
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

    static func defaultTieredNetworkEntryValidator() -> TieredNetworkEntryValidator {
        return TieredNetworkEntryValidator(
            rules: [
                TieredNetworkEntryLocaleLengthRule(maxLength: 1000),
                TieredNetworkEntryAttemptsRangeRule(min: 1000, max: 86400),
                TieredNetworkEntryRequiredTitleRule(message: "tiered network entry needs this field"),
                TieredNetworkEntryRequiredLocaleRule(message: "tiered network entry needs an entry"),
            ]
        )
    }
}
