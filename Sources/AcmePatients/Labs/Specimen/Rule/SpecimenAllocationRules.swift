import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen allocation must pass. Check returns its problems, or none.
    protocol SpecimenAllocationRule {
        func check(_ item: SpecimenAllocation) -> [String]
    }

    final class SpecimenAllocationRequiredRegionRule: SpecimenAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenAllocation) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenAllocationTitleLengthRule: SpecimenAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenAllocationRequiredCodeRule: SpecimenAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenAllocationRequiredTitleRule: SpecimenAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a specimen allocation.
    final class SpecimenAllocationValidator {
        var rules: [any SpecimenAllocationRule]

        init(rules: [any SpecimenAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenAllocation]) -> [String: [String]] {
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

    static func defaultSpecimenAllocationValidator() -> SpecimenAllocationValidator {
        return SpecimenAllocationValidator(
            rules: [
                SpecimenAllocationRequiredRegionRule(message: "specimen allocation needs a value"),
                SpecimenAllocationTitleLengthRule(maxLength: 16),
                SpecimenAllocationRequiredCodeRule(message: "specimen allocation needs a value"),
                SpecimenAllocationRequiredTitleRule(message: "specimen allocation needs an entry"),
            ]
        )
    }
}
