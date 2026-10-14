import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a manual float pool target must pass. Check returns its problems, or none.
    protocol ManualFloatPoolTargetRule {
        func check(_ item: ManualFloatPoolTarget) -> [String]
    }

    final class ManualFloatPoolTargetRequiredRegionRule: ManualFloatPoolTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualFloatPoolTarget) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualFloatPoolTargetCodePrefixRule: ManualFloatPoolTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualFloatPoolTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualFloatPoolTargetProcedureCodeLengthRule: ManualFloatPoolTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFloatPoolTarget) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualFloatPoolTargetRequiredCodeRule: ManualFloatPoolTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualFloatPoolTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualFloatPoolTargetGraceDaysRangeRule: ManualFloatPoolTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualFloatPoolTarget) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual float pool target.
    final class ManualFloatPoolTargetValidator {
        var rules: [any ManualFloatPoolTargetRule]

        init(rules: [any ManualFloatPoolTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualFloatPoolTarget) -> [String] {
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

        func requireValid(_ item: ManualFloatPoolTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualFloatPoolTarget]) -> [String: [String]] {
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

    static func defaultManualFloatPoolTargetValidator() -> ManualFloatPoolTargetValidator {
        return ManualFloatPoolTargetValidator(
            rules: [
                ManualFloatPoolTargetRequiredRegionRule(message: "manual float pool target needs this field"),
                ManualFloatPoolTargetCodePrefixRule(prefix: "REF"),
                ManualFloatPoolTargetProcedureCodeLengthRule(maxLength: 86400),
                ManualFloatPoolTargetRequiredCodeRule(message: "manual float pool target needs a value"),
                ManualFloatPoolTargetGraceDaysRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
