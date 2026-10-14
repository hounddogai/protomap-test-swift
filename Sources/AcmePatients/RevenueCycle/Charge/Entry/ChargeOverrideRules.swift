import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge override must pass. Check returns its problems, or none.
    protocol ChargeOverrideRule {
        func check(_ item: ChargeOverride) -> [String]
    }

    final class ChargeOverrideCodePrefixRule: ChargeOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ChargeOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ChargeOverrideDiagnosisCodeLengthRule: ChargeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeOverride) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeOverrideDurationMinutesRangeRule: ChargeOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeOverride) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge override.
    final class ChargeOverrideValidator {
        var rules: [any ChargeOverrideRule]

        init(rules: [any ChargeOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeOverride) -> [String] {
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

        func requireValid(_ item: ChargeOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeOverride]) -> [String: [String]] {
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

    static func defaultChargeOverrideValidator() -> ChargeOverrideValidator {
        return ChargeOverrideValidator(
            rules: [
                ChargeOverrideCodePrefixRule(prefix: "X"),
                ChargeOverrideDiagnosisCodeLengthRule(maxLength: 80),
                ChargeOverrideDurationMinutesRangeRule(min: 64, max: 64),
            ]
        )
    }
}
