import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered overtime override must pass. Check returns its problems, or none.
    protocol TieredOvertimeOverrideRule {
        func check(_ item: TieredOvertimeOverride) -> [String]
    }

    final class TieredOvertimeOverrideFloorValueRangeRule: TieredOvertimeOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredOvertimeOverride) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredOvertimeOverrideCodePrefixRule: TieredOvertimeOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredOvertimeOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredOvertimeOverrideAllowedNameRule: TieredOvertimeOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredOvertimeOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    final class TieredOvertimeOverrideCodeLengthRule: TieredOvertimeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredOvertimeOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredOvertimeOverrideRequiredCodeRule: TieredOvertimeOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOvertimeOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredOvertimeOverrideRequiredProcedureCodeRule: TieredOvertimeOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOvertimeOverride) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered overtime override.
    final class TieredOvertimeOverrideValidator {
        var rules: [any TieredOvertimeOverrideRule]

        init(rules: [any TieredOvertimeOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredOvertimeOverride) -> [String] {
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

        func requireValid(_ item: TieredOvertimeOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredOvertimeOverride]) -> [String: [String]] {
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

    static func defaultTieredOvertimeOverrideValidator() -> TieredOvertimeOverrideValidator {
        return TieredOvertimeOverrideValidator(
            rules: [
                TieredOvertimeOverrideFloorValueRangeRule(min: 6.9, max: 2042.7),
                TieredOvertimeOverrideCodePrefixRule(prefix: "Q"),
                TieredOvertimeOverrideAllowedNameRule(allowed: []),
                TieredOvertimeOverrideCodeLengthRule(maxLength: 80),
                TieredOvertimeOverrideRequiredCodeRule(message: "tiered overtime override needs a value"),
                TieredOvertimeOverrideRequiredProcedureCodeRule(message: "tiered overtime override needs an entry"),
            ]
        )
    }
}
