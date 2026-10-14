import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary credential allocation must pass. Check returns its problems, or none.
    protocol PrimaryCredentialAllocationRule {
        func check(_ item: PrimaryCredentialAllocation) -> [String]
    }

    final class PrimaryCredentialAllocationRequiredContactEmailRule: PrimaryCredentialAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCredentialAllocation) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCredentialAllocationRequiredEncounterIDRule: PrimaryCredentialAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCredentialAllocation) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCredentialAllocationRequiredTitleRule: PrimaryCredentialAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCredentialAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCredentialAllocationRequiredCodeRule: PrimaryCredentialAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCredentialAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCredentialAllocationCodeLengthRule: PrimaryCredentialAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCredentialAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCredentialAllocationCapacityRangeRule: PrimaryCredentialAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCredentialAllocation) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary credential allocation.
    final class PrimaryCredentialAllocationValidator {
        var rules: [any PrimaryCredentialAllocationRule]

        init(rules: [any PrimaryCredentialAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCredentialAllocation) -> [String] {
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

        func requireValid(_ item: PrimaryCredentialAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCredentialAllocation]) -> [String: [String]] {
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

    static func defaultPrimaryCredentialAllocationValidator() -> PrimaryCredentialAllocationValidator {
        return PrimaryCredentialAllocationValidator(
            rules: [
                PrimaryCredentialAllocationRequiredContactEmailRule(
                    message: "primary credential allocation needs an entry"
                ),
                PrimaryCredentialAllocationRequiredEncounterIDRule(
                    message: "primary credential allocation needs an entry"
                ),
                PrimaryCredentialAllocationRequiredTitleRule(message: "primary credential allocation needs an entry"),
                PrimaryCredentialAllocationRequiredCodeRule(message: "primary credential allocation needs an entry"),
                PrimaryCredentialAllocationCodeLengthRule(maxLength: 255),
                PrimaryCredentialAllocationCapacityRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
