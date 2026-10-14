import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive discharge plan mapping must pass. Check returns its problems, or none.
    protocol AdaptiveDischargePlanMappingRule {
        func check(_ item: AdaptiveDischargePlanMapping) -> [String]
    }

    final class AdaptiveDischargePlanMappingCodePrefixRule: AdaptiveDischargePlanMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveDischargePlanMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveDischargePlanMappingRequiredProcedureCodeRule: AdaptiveDischargePlanMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDischargePlanMapping) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDischargePlanMappingProcedureCodeLengthRule: AdaptiveDischargePlanMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDischargePlanMapping) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveDischargePlanMappingRegionLengthRule: AdaptiveDischargePlanMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDischargePlanMapping) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveDischargePlanMappingRequiredCodeRule: AdaptiveDischargePlanMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDischargePlanMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDischargePlanMappingNameLengthRule: AdaptiveDischargePlanMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDischargePlanMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive discharge plan mapping.
    final class AdaptiveDischargePlanMappingValidator {
        var rules: [any AdaptiveDischargePlanMappingRule]

        init(rules: [any AdaptiveDischargePlanMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveDischargePlanMapping) -> [String] {
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

        func requireValid(_ item: AdaptiveDischargePlanMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveDischargePlanMapping]) -> [String: [String]] {
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

    static func defaultAdaptiveDischargePlanMappingValidator() -> AdaptiveDischargePlanMappingValidator {
        return AdaptiveDischargePlanMappingValidator(
            rules: [
                AdaptiveDischargePlanMappingCodePrefixRule(prefix: "REF"),
                AdaptiveDischargePlanMappingRequiredProcedureCodeRule(
                    message: "adaptive discharge plan mapping needs this field"
                ),
                AdaptiveDischargePlanMappingProcedureCodeLengthRule(maxLength: 64),
                AdaptiveDischargePlanMappingRegionLengthRule(maxLength: 120),
                AdaptiveDischargePlanMappingRequiredCodeRule(message: "adaptive discharge plan mapping needs a value"),
                AdaptiveDischargePlanMappingNameLengthRule(maxLength: 64),
            ]
        )
    }
}
