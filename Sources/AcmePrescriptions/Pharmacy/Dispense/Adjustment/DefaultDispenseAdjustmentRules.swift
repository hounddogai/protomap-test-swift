import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default dispense adjustment must pass. Check returns its problems, or none.
    protocol DefaultDispenseAdjustmentRule {
        func check(_ item: DefaultDispenseAdjustment) -> [String]
    }

    final class DefaultDispenseAdjustmentCodePrefixRule: DefaultDispenseAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultDispenseAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultDispenseAdjustmentRequiredCodeRule: DefaultDispenseAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultDispenseAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultDispenseAdjustmentTitleLengthRule: DefaultDispenseAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultDispenseAdjustment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultDispenseAdjustmentNotesLengthRule: DefaultDispenseAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultDispenseAdjustment) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default dispense adjustment.
    final class DefaultDispenseAdjustmentValidator {
        var rules: [any DefaultDispenseAdjustmentRule]

        init(rules: [any DefaultDispenseAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultDispenseAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultDispenseAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultDispenseAdjustment]) -> [String: [String]] {
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

    static func defaultDefaultDispenseAdjustmentValidator() -> DefaultDispenseAdjustmentValidator {
        return DefaultDispenseAdjustmentValidator(
            rules: [
                DefaultDispenseAdjustmentCodePrefixRule(prefix: "ACM"),
                DefaultDispenseAdjustmentRequiredCodeRule(message: "default dispense adjustment needs a value"),
                DefaultDispenseAdjustmentTitleLengthRule(maxLength: 1000),
                DefaultDispenseAdjustmentNotesLengthRule(maxLength: 1000),
            ]
        )
    }
}
