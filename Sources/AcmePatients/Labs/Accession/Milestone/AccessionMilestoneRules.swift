import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession milestone must pass. Check returns its problems, or none.
    protocol AccessionMilestoneRule {
        func check(_ item: AccessionMilestone) -> [String]
    }

    final class AccessionMilestoneRequiredCodeRule: AccessionMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionMilestoneCodePrefixRule: AccessionMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AccessionMilestoneCodeLengthRule: AccessionMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionMilestoneRequiredTimezoneRule: AccessionMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionMilestone) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionMilestoneRequiredClinicianIDRule: AccessionMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionMilestone) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a accession milestone.
    final class AccessionMilestoneValidator {
        var rules: [any AccessionMilestoneRule]

        init(rules: [any AccessionMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionMilestone]) -> [String: [String]] {
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

    static func defaultAccessionMilestoneValidator() -> AccessionMilestoneValidator {
        return AccessionMilestoneValidator(
            rules: [
                AccessionMilestoneRequiredCodeRule(message: "accession milestone needs this field"),
                AccessionMilestoneCodePrefixRule(prefix: "OPS"),
                AccessionMilestoneCodeLengthRule(maxLength: 1000),
                AccessionMilestoneRequiredTimezoneRule(message: "accession milestone needs an entry"),
                AccessionMilestoneRequiredClinicianIDRule(message: "accession milestone needs this field"),
            ]
        )
    }
}
