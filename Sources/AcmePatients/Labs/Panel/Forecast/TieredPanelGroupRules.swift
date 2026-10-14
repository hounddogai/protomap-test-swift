import AcmePlatform
import Foundation

extension Labs {
    /// A rule a tiered panel group must pass. Check returns its problems, or none.
    protocol TieredPanelGroupRule {
        func check(_ item: TieredPanelGroup) -> [String]
    }

    final class TieredPanelGroupRequiredCodeRule: TieredPanelGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPanelGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredPanelGroupCurrencyLengthRule: TieredPanelGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPanelGroup) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPanelGroupCodePrefixRule: TieredPanelGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredPanelGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredPanelGroupAcuityRangeRule: TieredPanelGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredPanelGroup) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredPanelGroupCodeLengthRule: TieredPanelGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPanelGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered panel group.
    final class TieredPanelGroupValidator {
        var rules: [any TieredPanelGroupRule]

        init(rules: [any TieredPanelGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredPanelGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredPanelGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredPanelGroup]) -> [String: [String]] {
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

    static func defaultTieredPanelGroupValidator() -> TieredPanelGroupValidator {
        return TieredPanelGroupValidator(
            rules: [
                TieredPanelGroupRequiredCodeRule(message: "tiered panel group needs an entry"),
                TieredPanelGroupCurrencyLengthRule(maxLength: 16),
                TieredPanelGroupCodePrefixRule(prefix: "ACM"),
                TieredPanelGroupAcuityRangeRule(min: 255, max: 86400),
                TieredPanelGroupCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
