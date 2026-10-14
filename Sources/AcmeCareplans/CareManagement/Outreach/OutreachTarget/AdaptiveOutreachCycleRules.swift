import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive outreach cycle must pass. Check returns its problems, or none.
    protocol AdaptiveOutreachCycleRule {
        func check(_ item: AdaptiveOutreachCycle) -> [String]
    }

    final class AdaptiveOutreachCycleBedLengthRule: AdaptiveOutreachCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveOutreachCycle) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveOutreachCycleRequiredNameRule: AdaptiveOutreachCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOutreachCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveOutreachCycleRequiredCodeRule: AdaptiveOutreachCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOutreachCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive outreach cycle.
    final class AdaptiveOutreachCycleValidator {
        var rules: [any AdaptiveOutreachCycleRule]

        init(rules: [any AdaptiveOutreachCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveOutreachCycle) -> [String] {
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

        func requireValid(_ item: AdaptiveOutreachCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveOutreachCycle]) -> [String: [String]] {
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

    static func defaultAdaptiveOutreachCycleValidator() -> AdaptiveOutreachCycleValidator {
        return AdaptiveOutreachCycleValidator(
            rules: [
                AdaptiveOutreachCycleBedLengthRule(maxLength: 16),
                AdaptiveOutreachCycleRequiredNameRule(message: "adaptive outreach cycle needs a value"),
                AdaptiveOutreachCycleRequiredCodeRule(message: "adaptive outreach cycle needs this field"),
            ]
        )
    }
}
