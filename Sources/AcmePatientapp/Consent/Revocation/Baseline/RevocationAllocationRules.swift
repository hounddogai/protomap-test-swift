import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation allocation must pass. Check returns its problems, or none.
    protocol RevocationAllocationRule {
        func check(_ item: RevocationAllocation) -> [String]
    }

    final class RevocationAllocationVisitMinutesRangeRule: RevocationAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationAllocation) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RevocationAllocationRequiredWardRule: RevocationAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationAllocation) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationAllocationContactEmailLengthRule: RevocationAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationAllocation) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationAllocationLabelLengthRule: RevocationAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationAllocation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationAllocationRequiredContactEmailRule: RevocationAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationAllocation) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a revocation allocation.
    final class RevocationAllocationValidator {
        var rules: [any RevocationAllocationRule]

        init(rules: [any RevocationAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationAllocation]) -> [String: [String]] {
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

    static func defaultRevocationAllocationValidator() -> RevocationAllocationValidator {
        return RevocationAllocationValidator(
            rules: [
                RevocationAllocationVisitMinutesRangeRule(min: 80, max: 120),
                RevocationAllocationRequiredWardRule(message: "revocation allocation needs an entry"),
                RevocationAllocationContactEmailLengthRule(maxLength: 16),
                RevocationAllocationLabelLengthRule(maxLength: 120),
                RevocationAllocationRequiredContactEmailRule(message: "revocation allocation needs an entry"),
            ]
        )
    }
}
