import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict witness audit must pass. Check returns its problems, or none.
    protocol StrictWitnessAuditRule {
        func check(_ item: StrictWitnessAudit) -> [String]
    }

    final class StrictWitnessAuditCodePrefixRule: StrictWitnessAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictWitnessAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictWitnessAuditRequiredChannelRule: StrictWitnessAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWitnessAudit) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictWitnessAuditRequiredLabelRule: StrictWitnessAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWitnessAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictWitnessAuditCodeLengthRule: StrictWitnessAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictWitnessAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictWitnessAuditVersionRangeRule: StrictWitnessAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictWitnessAudit) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a strict witness audit.
    final class StrictWitnessAuditValidator {
        var rules: [any StrictWitnessAuditRule]

        init(rules: [any StrictWitnessAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictWitnessAudit) -> [String] {
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

        func requireValid(_ item: StrictWitnessAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictWitnessAudit]) -> [String: [String]] {
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

    static func defaultStrictWitnessAuditValidator() -> StrictWitnessAuditValidator {
        return StrictWitnessAuditValidator(
            rules: [
                StrictWitnessAuditCodePrefixRule(prefix: "X"),
                StrictWitnessAuditRequiredChannelRule(message: "strict witness audit needs an entry"),
                StrictWitnessAuditRequiredLabelRule(message: "strict witness audit needs this field"),
                StrictWitnessAuditCodeLengthRule(maxLength: 80),
                StrictWitnessAuditVersionRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
