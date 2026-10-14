import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered priority summary must pass. Check returns its problems, or none.
    protocol TieredPrioritySummaryRule {
        func check(_ item: TieredPrioritySummary) -> [String]
    }

    final class TieredPrioritySummaryRequiredRegionRule: TieredPrioritySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPrioritySummary) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredPrioritySummaryCodePrefixRule: TieredPrioritySummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredPrioritySummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredPrioritySummaryQuantityRangeRule: TieredPrioritySummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredPrioritySummary) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredPrioritySummaryRequiredChecksumRule: TieredPrioritySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPrioritySummary) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredPrioritySummaryChecksumLengthRule: TieredPrioritySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPrioritySummary) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPrioritySummaryCodeLengthRule: TieredPrioritySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPrioritySummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered priority summary.
    final class TieredPrioritySummaryValidator {
        var rules: [any TieredPrioritySummaryRule]

        init(rules: [any TieredPrioritySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredPrioritySummary) -> [String] {
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

        func requireValid(_ item: TieredPrioritySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredPrioritySummary]) -> [String: [String]] {
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

    static func defaultTieredPrioritySummaryValidator() -> TieredPrioritySummaryValidator {
        return TieredPrioritySummaryValidator(
            rules: [
                TieredPrioritySummaryRequiredRegionRule(message: "tiered priority summary needs a value"),
                TieredPrioritySummaryCodePrefixRule(prefix: "X"),
                TieredPrioritySummaryQuantityRangeRule(min: 255, max: 3600),
                TieredPrioritySummaryRequiredChecksumRule(message: "tiered priority summary needs an entry"),
                TieredPrioritySummaryChecksumLengthRule(maxLength: 64),
                TieredPrioritySummaryCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
