import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending reference range override must pass. Check returns its problems, or none.
    protocol PendingReferenceRangeOverrideRule {
        func check(_ item: PendingReferenceRangeOverride) -> [String]
    }

    final class PendingReferenceRangeOverrideRequiredCodeRule: PendingReferenceRangeOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReferenceRangeOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReferenceRangeOverridePhoneLengthRule: PendingReferenceRangeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReferenceRangeOverride) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReferenceRangeOverrideRequiredExternalRefRule: PendingReferenceRangeOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReferenceRangeOverride) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReferenceRangeOverrideLabelLengthRule: PendingReferenceRangeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReferenceRangeOverride) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending reference range override.
    final class PendingReferenceRangeOverrideValidator {
        var rules: [any PendingReferenceRangeOverrideRule]

        init(rules: [any PendingReferenceRangeOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReferenceRangeOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingReferenceRangeOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReferenceRangeOverride]) -> [String: [String]] {
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

    static func defaultPendingReferenceRangeOverrideValidator() -> PendingReferenceRangeOverrideValidator {
        return PendingReferenceRangeOverrideValidator(
            rules: [
                PendingReferenceRangeOverrideRequiredCodeRule(
                    message: "pending reference range override needs a value"
                ),
                PendingReferenceRangeOverridePhoneLengthRule(maxLength: 80),
                PendingReferenceRangeOverrideRequiredExternalRefRule(
                    message: "pending reference range override needs an entry"
                ),
                PendingReferenceRangeOverrideLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
