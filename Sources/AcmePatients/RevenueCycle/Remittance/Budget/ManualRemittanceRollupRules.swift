import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual remittance rollup must pass. Check returns its problems, or none.
    protocol ManualRemittanceRollupRule {
        func check(_ item: ManualRemittanceRollup) -> [String]
    }

    final class ManualRemittanceRollupRegionLengthRule: ManualRemittanceRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRemittanceRollup) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRemittanceRollupNameLengthRule: ManualRemittanceRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRemittanceRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRemittanceRollupRequiredDescriptionRule: ManualRemittanceRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRemittanceRollup) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual remittance rollup.
    final class ManualRemittanceRollupValidator {
        var rules: [any ManualRemittanceRollupRule]

        init(rules: [any ManualRemittanceRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRemittanceRollup) -> [String] {
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

        func requireValid(_ item: ManualRemittanceRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRemittanceRollup]) -> [String: [String]] {
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

    static func defaultManualRemittanceRollupValidator() -> ManualRemittanceRollupValidator {
        return ManualRemittanceRollupValidator(
            rules: [
                ManualRemittanceRollupRegionLengthRule(maxLength: 80),
                ManualRemittanceRollupNameLengthRule(maxLength: 80),
                ManualRemittanceRollupRequiredDescriptionRule(message: "manual remittance rollup needs this field"),
            ]
        )
    }
}
