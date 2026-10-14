import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual discharge plan profile must pass. Check returns its problems, or none.
    protocol ManualDischargePlanProfileRule {
        func check(_ item: ManualDischargePlanProfile) -> [String]
    }

    final class ManualDischargePlanProfileRequiredSourceRule: ManualDischargePlanProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDischargePlanProfile) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDischargePlanProfileCodePrefixRule: ManualDischargePlanProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualDischargePlanProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualDischargePlanProfileRequiredProcedureCodeRule: ManualDischargePlanProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDischargePlanProfile) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual discharge plan profile.
    final class ManualDischargePlanProfileValidator {
        var rules: [any ManualDischargePlanProfileRule]

        init(rules: [any ManualDischargePlanProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDischargePlanProfile) -> [String] {
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

        func requireValid(_ item: ManualDischargePlanProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDischargePlanProfile]) -> [String: [String]] {
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

    static func defaultManualDischargePlanProfileValidator() -> ManualDischargePlanProfileValidator {
        return ManualDischargePlanProfileValidator(
            rules: [
                ManualDischargePlanProfileRequiredSourceRule(message: "manual discharge plan profile needs a value"),
                ManualDischargePlanProfileCodePrefixRule(prefix: "Q"),
                ManualDischargePlanProfileRequiredProcedureCodeRule(
                    message: "manual discharge plan profile needs a value"
                ),
            ]
        )
    }
}
