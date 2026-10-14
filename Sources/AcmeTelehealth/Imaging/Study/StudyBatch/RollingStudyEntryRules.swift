import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling study entry must pass. Check returns its problems, or none.
    protocol RollingStudyEntryRule {
        func check(_ item: RollingStudyEntry) -> [String]
    }

    final class RollingStudyEntryNameLengthRule: RollingStudyEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingStudyEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingStudyEntryRequiredPhoneRule: RollingStudyEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingStudyEntry) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingStudyEntryRequiredCodeRule: RollingStudyEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingStudyEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingStudyEntryCodePrefixRule: RollingStudyEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingStudyEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingStudyEntryRequiredEncounterIDRule: RollingStudyEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingStudyEntry) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling study entry.
    final class RollingStudyEntryValidator {
        var rules: [any RollingStudyEntryRule]

        init(rules: [any RollingStudyEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingStudyEntry) -> [String] {
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

        func requireValid(_ item: RollingStudyEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingStudyEntry]) -> [String: [String]] {
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

    static func defaultRollingStudyEntryValidator() -> RollingStudyEntryValidator {
        return RollingStudyEntryValidator(
            rules: [
                RollingStudyEntryNameLengthRule(maxLength: 32),
                RollingStudyEntryRequiredPhoneRule(message: "rolling study entry needs an entry"),
                RollingStudyEntryRequiredCodeRule(message: "rolling study entry needs a value"),
                RollingStudyEntryCodePrefixRule(prefix: "OPS"),
                RollingStudyEntryRequiredEncounterIDRule(message: "rolling study entry needs an entry"),
            ]
        )
    }
}
