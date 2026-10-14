import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read allocation must pass. Check returns its problems, or none.
    protocol ReadAllocationRule {
        func check(_ item: ReadAllocation) -> [String]
    }

    final class ReadAllocationCountryLengthRule: ReadAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadAllocation) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadAllocationRequiredCountryRule: ReadAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadAllocation) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadAllocationNameLengthRule: ReadAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadAllocation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadAllocationRequiredDescriptionRule: ReadAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadAllocation) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadAllocationDescriptionLengthRule: ReadAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadAllocation) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a read allocation.
    final class ReadAllocationValidator {
        var rules: [any ReadAllocationRule]

        init(rules: [any ReadAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadAllocation]) -> [String: [String]] {
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

    static func defaultReadAllocationValidator() -> ReadAllocationValidator {
        return ReadAllocationValidator(
            rules: [
                ReadAllocationCountryLengthRule(maxLength: 32),
                ReadAllocationRequiredCountryRule(message: "read allocation needs this field"),
                ReadAllocationNameLengthRule(maxLength: 120),
                ReadAllocationRequiredDescriptionRule(message: "read allocation needs an entry"),
                ReadAllocationDescriptionLengthRule(maxLength: 255),
            ]
        )
    }
}
