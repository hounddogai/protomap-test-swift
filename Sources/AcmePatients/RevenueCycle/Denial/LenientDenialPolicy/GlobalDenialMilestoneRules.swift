import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global denial milestone must pass. Check returns its problems, or none.
    protocol GlobalDenialMilestoneRule {
        func check(_ item: GlobalDenialMilestone) -> [String]
    }

    final class GlobalDenialMilestoneCodePrefixRule: GlobalDenialMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalDenialMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalDenialMilestoneEncounterIDLengthRule: GlobalDenialMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDenialMilestone) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDenialMilestoneRequiredCodeRule: GlobalDenialMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDenialMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDenialMilestoneRequiredNameRule: GlobalDenialMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDenialMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDenialMilestoneRequiredPhoneRule: GlobalDenialMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDenialMilestone) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global denial milestone.
    final class GlobalDenialMilestoneValidator {
        var rules: [any GlobalDenialMilestoneRule]

        init(rules: [any GlobalDenialMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDenialMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalDenialMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDenialMilestone]) -> [String: [String]] {
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

    static func defaultGlobalDenialMilestoneValidator() -> GlobalDenialMilestoneValidator {
        return GlobalDenialMilestoneValidator(
            rules: [
                GlobalDenialMilestoneCodePrefixRule(prefix: "ACM"),
                GlobalDenialMilestoneEncounterIDLengthRule(maxLength: 255),
                GlobalDenialMilestoneRequiredCodeRule(message: "global denial milestone needs this field"),
                GlobalDenialMilestoneRequiredNameRule(message: "global denial milestone needs this field"),
                GlobalDenialMilestoneRequiredPhoneRule(message: "global denial milestone needs a value"),
            ]
        )
    }
}
