import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential mapping must pass. Check returns its problems, or none.
    protocol CredentialMappingRule {
        func check(_ item: CredentialMapping) -> [String]
    }

    final class CredentialMappingSegmentLengthRule: CredentialMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialMapping) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialMappingPatientRefLengthRule: CredentialMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialMapping) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialMappingQuantityRangeRule: CredentialMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialMapping) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential mapping.
    final class CredentialMappingValidator {
        var rules: [any CredentialMappingRule]

        init(rules: [any CredentialMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialMapping) -> [String] {
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

        func requireValid(_ item: CredentialMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialMapping]) -> [String: [String]] {
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

    static func defaultCredentialMappingValidator() -> CredentialMappingValidator {
        return CredentialMappingValidator(
            rules: [
                CredentialMappingSegmentLengthRule(maxLength: 80),
                CredentialMappingPatientRefLengthRule(maxLength: 1000),
                CredentialMappingQuantityRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
