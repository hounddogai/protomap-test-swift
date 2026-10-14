import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual outreach slot must pass. Check returns its problems, or none.
    protocol ManualOutreachSlotRule {
        func check(_ item: ManualOutreachSlot) -> [String]
    }

    final class ManualOutreachSlotAllowedNameRule: ManualOutreachSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualOutreachSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class ManualOutreachSlotExternalRefLengthRule: ManualOutreachSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOutreachSlot) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualOutreachSlotCodeLengthRule: ManualOutreachSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOutreachSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualOutreachSlotCodePrefixRule: ManualOutreachSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualOutreachSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual outreach slot.
    final class ManualOutreachSlotValidator {
        var rules: [any ManualOutreachSlotRule]

        init(rules: [any ManualOutreachSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualOutreachSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualOutreachSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualOutreachSlot]) -> [String: [String]] {
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

    static func defaultManualOutreachSlotValidator() -> ManualOutreachSlotValidator {
        return ManualOutreachSlotValidator(
            rules: [
                ManualOutreachSlotAllowedNameRule(allowed: []),
                ManualOutreachSlotExternalRefLengthRule(maxLength: 255),
                ManualOutreachSlotCodeLengthRule(maxLength: 1000),
                ManualOutreachSlotCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
