import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority claim must pass. Check returns its problems, or none.
    protocol PriorityClaimRule {
        func check(_ item: PriorityClaim) -> [String]
    }

    final class PriorityClaimCodePrefixRule: PriorityClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PriorityClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PriorityClaimCodeLengthRule: PriorityClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityClaimSequenceRangeRule: PriorityClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityClaim) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityClaimRequiredCodeRule: PriorityClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityClaimRequiredEncounterIDRule: PriorityClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityClaim) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority claim.
    final class PriorityClaimValidator {
        var rules: [any PriorityClaimRule]

        init(rules: [any PriorityClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityClaim]) -> [String: [String]] {
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

    static func defaultPriorityClaimValidator() -> PriorityClaimValidator {
        return PriorityClaimValidator(
            rules: [
                PriorityClaimCodePrefixRule(prefix: "Q"),
                PriorityClaimCodeLengthRule(maxLength: 64),
                PriorityClaimSequenceRangeRule(min: 255, max: 1000),
                PriorityClaimRequiredCodeRule(message: "priority claim needs an entry"),
                PriorityClaimRequiredEncounterIDRule(message: "priority claim needs a value"),
            ]
        )
    }
}
