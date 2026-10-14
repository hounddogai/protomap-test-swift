import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach cycle must pass. Check returns its problems, or none.
    protocol OutreachCycleRule {
        func check(_ item: OutreachCycle) -> [String]
    }

    final class OutreachCycleCodePrefixRule: OutreachCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OutreachCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OutreachCyclePhoneLengthRule: OutreachCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachCycle) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachCycleRequiredNameRule: OutreachCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachCycleNameLengthRule: OutreachCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach cycle.
    final class OutreachCycleValidator {
        var rules: [any OutreachCycleRule]

        init(rules: [any OutreachCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachCycle]) -> [String: [String]] {
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

    static func defaultOutreachCycleValidator() -> OutreachCycleValidator {
        return OutreachCycleValidator(
            rules: [
                OutreachCycleCodePrefixRule(prefix: "X"),
                OutreachCyclePhoneLengthRule(maxLength: 86400),
                OutreachCycleRequiredNameRule(message: "outreach cycle needs a value"),
                OutreachCycleNameLengthRule(maxLength: 64),
            ]
        )
    }
}
