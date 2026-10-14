import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy panel threshold must pass. Check returns its problems, or none.
    protocol LegacyPanelThresholdRule {
        func check(_ item: LegacyPanelThreshold) -> [String]
    }

    final class LegacyPanelThresholdRequiredNotesRule: LegacyPanelThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyPanelThreshold) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyPanelThresholdTitleLengthRule: LegacyPanelThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyPanelThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyPanelThresholdCodeLengthRule: LegacyPanelThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyPanelThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyPanelThresholdChecksumLengthRule: LegacyPanelThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyPanelThreshold) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyPanelThresholdRequiredTitleRule: LegacyPanelThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyPanelThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy panel threshold.
    final class LegacyPanelThresholdValidator {
        var rules: [any LegacyPanelThresholdRule]

        init(rules: [any LegacyPanelThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyPanelThreshold) -> [String] {
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

        func requireValid(_ item: LegacyPanelThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyPanelThreshold]) -> [String: [String]] {
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

    static func defaultLegacyPanelThresholdValidator() -> LegacyPanelThresholdValidator {
        return LegacyPanelThresholdValidator(
            rules: [
                LegacyPanelThresholdRequiredNotesRule(message: "legacy panel threshold needs a value"),
                LegacyPanelThresholdTitleLengthRule(maxLength: 32),
                LegacyPanelThresholdCodeLengthRule(maxLength: 64),
                LegacyPanelThresholdChecksumLengthRule(maxLength: 86400),
                LegacyPanelThresholdRequiredTitleRule(message: "legacy panel threshold needs a value"),
            ]
        )
    }
}
