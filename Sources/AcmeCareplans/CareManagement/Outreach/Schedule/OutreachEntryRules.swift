import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach entry must pass. Check returns its problems, or none.
    protocol OutreachEntryRule {
        func check(_ item: OutreachEntry) -> [String]
    }

    final class OutreachEntryThresholdRangeRule: OutreachEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachEntry) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachEntryCodeLengthRule: OutreachEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachEntryRequiredTitleRule: OutreachEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachEntryRequiredClinicianIDRule: OutreachEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachEntry) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a outreach entry.
    final class OutreachEntryValidator {
        var rules: [any OutreachEntryRule]

        init(rules: [any OutreachEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachEntry]) -> [String: [String]] {
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

    static func defaultOutreachEntryValidator() -> OutreachEntryValidator {
        return OutreachEntryValidator(
            rules: [
                OutreachEntryThresholdRangeRule(min: 5.5, max: 3712.0),
                OutreachEntryCodeLengthRule(maxLength: 120),
                OutreachEntryRequiredTitleRule(message: "outreach entry needs a value"),
                OutreachEntryRequiredClinicianIDRule(message: "outreach entry needs this field"),
            ]
        )
    }
}
