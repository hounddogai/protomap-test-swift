import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default panel override must pass. Check returns its problems, or none.
    protocol DefaultPanelOverrideRule {
        func check(_ item: DefaultPanelOverride) -> [String]
    }

    final class DefaultPanelOverrideOwnerIDLengthRule: DefaultPanelOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultPanelOverride) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultPanelOverrideRetriesRangeRule: DefaultPanelOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultPanelOverride) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultPanelOverrideQuantityRangeRule: DefaultPanelOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultPanelOverride) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultPanelOverrideCodeLengthRule: DefaultPanelOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultPanelOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default panel override.
    final class DefaultPanelOverrideValidator {
        var rules: [any DefaultPanelOverrideRule]

        init(rules: [any DefaultPanelOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultPanelOverride) -> [String] {
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

        func requireValid(_ item: DefaultPanelOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultPanelOverride]) -> [String: [String]] {
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

    static func defaultDefaultPanelOverrideValidator() -> DefaultPanelOverrideValidator {
        return DefaultPanelOverrideValidator(
            rules: [
                DefaultPanelOverrideOwnerIDLengthRule(maxLength: 1000),
                DefaultPanelOverrideRetriesRangeRule(min: 64, max: 86400),
                DefaultPanelOverrideQuantityRangeRule(min: 64, max: 3600),
                DefaultPanelOverrideCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
