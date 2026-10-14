import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default credential mapping must pass. Check returns its problems, or none.
    protocol DefaultCredentialMappingRule {
        func check(_ item: DefaultCredentialMapping) -> [String]
    }

    final class DefaultCredentialMappingRequiredSpecialtyRule: DefaultCredentialMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCredentialMapping) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCredentialMappingCodeLengthRule: DefaultCredentialMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCredentialMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCredentialMappingRequiredCodeRule: DefaultCredentialMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCredentialMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCredentialMappingLimitRangeRule: DefaultCredentialMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCredentialMapping) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCredentialMappingDiagnosisCodeLengthRule: DefaultCredentialMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCredentialMapping) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCredentialMappingSpecialtyLengthRule: DefaultCredentialMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCredentialMapping) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default credential mapping.
    final class DefaultCredentialMappingValidator {
        var rules: [any DefaultCredentialMappingRule]

        init(rules: [any DefaultCredentialMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCredentialMapping) -> [String] {
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

        func requireValid(_ item: DefaultCredentialMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCredentialMapping]) -> [String: [String]] {
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

    static func defaultDefaultCredentialMappingValidator() -> DefaultCredentialMappingValidator {
        return DefaultCredentialMappingValidator(
            rules: [
                DefaultCredentialMappingRequiredSpecialtyRule(message: "default credential mapping needs an entry"),
                DefaultCredentialMappingCodeLengthRule(maxLength: 80),
                DefaultCredentialMappingRequiredCodeRule(message: "default credential mapping needs this field"),
                DefaultCredentialMappingLimitRangeRule(min: 16, max: 255),
                DefaultCredentialMappingDiagnosisCodeLengthRule(maxLength: 255),
                DefaultCredentialMappingSpecialtyLengthRule(maxLength: 120),
            ]
        )
    }
}
