import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual formulary rollup must pass. Check returns its problems, or none.
    protocol ManualFormularyRollupRule {
        func check(_ item: ManualFormularyRollup) -> [String]
    }

    final class ManualFormularyRollupCodePrefixRule: ManualFormularyRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualFormularyRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualFormularyRollupNameLengthRule: ManualFormularyRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFormularyRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualFormularyRollupRequiredFacilityRule: ManualFormularyRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualFormularyRollup) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual formulary rollup.
    final class ManualFormularyRollupValidator {
        var rules: [any ManualFormularyRollupRule]

        init(rules: [any ManualFormularyRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualFormularyRollup) -> [String] {
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

        func requireValid(_ item: ManualFormularyRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualFormularyRollup]) -> [String: [String]] {
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

    static func defaultManualFormularyRollupValidator() -> ManualFormularyRollupValidator {
        return ManualFormularyRollupValidator(
            rules: [
                ManualFormularyRollupCodePrefixRule(prefix: "X"),
                ManualFormularyRollupNameLengthRule(maxLength: 3600),
                ManualFormularyRollupRequiredFacilityRule(message: "manual formulary rollup needs this field"),
            ]
        )
    }
}
