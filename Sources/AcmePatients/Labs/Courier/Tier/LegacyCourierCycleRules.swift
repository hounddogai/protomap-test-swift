import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy courier cycle must pass. Check returns its problems, or none.
    protocol LegacyCourierCycleRule {
        func check(_ item: LegacyCourierCycle) -> [String]
    }

    final class LegacyCourierCycleRequiredClinicianIDRule: LegacyCourierCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCourierCycle) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCourierCyclePhoneLengthRule: LegacyCourierCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCourierCycle) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCourierCycleCodePrefixRule: LegacyCourierCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyCourierCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyCourierCycleRequiredCodeRule: LegacyCourierCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCourierCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCourierCycleTitleLengthRule: LegacyCourierCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCourierCycle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy courier cycle.
    final class LegacyCourierCycleValidator {
        var rules: [any LegacyCourierCycleRule]

        init(rules: [any LegacyCourierCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCourierCycle) -> [String] {
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

        func requireValid(_ item: LegacyCourierCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCourierCycle]) -> [String: [String]] {
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

    static func defaultLegacyCourierCycleValidator() -> LegacyCourierCycleValidator {
        return LegacyCourierCycleValidator(
            rules: [
                LegacyCourierCycleRequiredClinicianIDRule(message: "legacy courier cycle needs a value"),
                LegacyCourierCyclePhoneLengthRule(maxLength: 255),
                LegacyCourierCycleCodePrefixRule(prefix: "ACM"),
                LegacyCourierCycleRequiredCodeRule(message: "legacy courier cycle needs an entry"),
                LegacyCourierCycleTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
