import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel record must pass. Check returns its problems, or none.
    protocol PanelRecordRule {
        func check(_ item: PanelRecord) -> [String]
    }

    final class PanelRecordRequiredCodeRule: PanelRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelRecordContactEmailLengthRule: PanelRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelRecord) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelRecordRequiredContactEmailRule: PanelRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelRecord) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelRecordCodePrefixRule: PanelRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel record.
    final class PanelRecordValidator {
        var rules: [any PanelRecordRule]

        init(rules: [any PanelRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelRecord) -> [String] {
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

        func requireValid(_ item: PanelRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelRecord]) -> [String: [String]] {
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

    static func defaultPanelRecordValidator() -> PanelRecordValidator {
        return PanelRecordValidator(
            rules: [
                PanelRecordRequiredCodeRule(message: "panel record needs a value"),
                PanelRecordContactEmailLengthRule(maxLength: 120),
                PanelRecordRequiredContactEmailRule(message: "panel record needs this field"),
                PanelRecordCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
