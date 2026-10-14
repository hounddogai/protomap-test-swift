import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual disclosure policy must pass. Check returns its problems, or none.
    protocol ManualDisclosurePolicyRule {
        func check(_ item: ManualDisclosurePolicy) -> [String]
    }

    final class ManualDisclosurePolicyRequiredCodeRule: ManualDisclosurePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDisclosurePolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDisclosurePolicyCodeLengthRule: ManualDisclosurePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDisclosurePolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualDisclosurePolicyRequiredDescriptionRule: ManualDisclosurePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDisclosurePolicy) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDisclosurePolicyRequiredSegmentRule: ManualDisclosurePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDisclosurePolicy) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual disclosure policy.
    final class ManualDisclosurePolicyValidator {
        var rules: [any ManualDisclosurePolicyRule]

        init(rules: [any ManualDisclosurePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDisclosurePolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualDisclosurePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDisclosurePolicy]) -> [String: [String]] {
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

    static func defaultManualDisclosurePolicyValidator() -> ManualDisclosurePolicyValidator {
        return ManualDisclosurePolicyValidator(
            rules: [
                ManualDisclosurePolicyRequiredCodeRule(message: "manual disclosure policy needs an entry"),
                ManualDisclosurePolicyCodeLengthRule(maxLength: 16),
                ManualDisclosurePolicyRequiredDescriptionRule(message: "manual disclosure policy needs an entry"),
                ManualDisclosurePolicyRequiredSegmentRule(message: "manual disclosure policy needs this field"),
            ]
        )
    }
}
