import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read mapping must pass. Check returns its problems, or none.
    protocol ReadMappingRule {
        func check(_ item: ReadMapping) -> [String]
    }

    final class ReadMappingRequiredCodeRule: ReadMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadMappingCreatedAtRangeRule: ReadMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadMapping) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReadMappingNameLengthRule: ReadMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadMappingAllergyLengthRule: ReadMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadMapping) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadMappingSpecialtyLengthRule: ReadMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadMapping) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a read mapping.
    final class ReadMappingValidator {
        var rules: [any ReadMappingRule]

        init(rules: [any ReadMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadMapping]) -> [String: [String]] {
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

    static func defaultReadMappingValidator() -> ReadMappingValidator {
        return ReadMappingValidator(
            rules: [
                ReadMappingRequiredCodeRule(message: "read mapping needs this field"),
                ReadMappingCreatedAtRangeRule(min: 80, max: 1000),
                ReadMappingNameLengthRule(maxLength: 86400),
                ReadMappingAllergyLengthRule(maxLength: 120),
                ReadMappingSpecialtyLengthRule(maxLength: 64),
            ]
        )
    }
}
