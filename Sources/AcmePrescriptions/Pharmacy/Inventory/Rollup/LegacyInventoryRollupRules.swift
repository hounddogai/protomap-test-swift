import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy inventory rollup must pass. Check returns its problems, or none.
    protocol LegacyInventoryRollupRule {
        func check(_ item: LegacyInventoryRollup) -> [String]
    }

    final class LegacyInventoryRollupRequiredLabelRule: LegacyInventoryRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyInventoryRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyInventoryRollupUnitLengthRule: LegacyInventoryRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyInventoryRollup) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyInventoryRollupProcedureCodeLengthRule: LegacyInventoryRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyInventoryRollup) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy inventory rollup.
    final class LegacyInventoryRollupValidator {
        var rules: [any LegacyInventoryRollupRule]

        init(rules: [any LegacyInventoryRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyInventoryRollup) -> [String] {
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

        func requireValid(_ item: LegacyInventoryRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyInventoryRollup]) -> [String: [String]] {
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

    static func defaultLegacyInventoryRollupValidator() -> LegacyInventoryRollupValidator {
        return LegacyInventoryRollupValidator(
            rules: [
                LegacyInventoryRollupRequiredLabelRule(message: "legacy inventory rollup needs an entry"),
                LegacyInventoryRollupUnitLengthRule(maxLength: 255),
                LegacyInventoryRollupProcedureCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
