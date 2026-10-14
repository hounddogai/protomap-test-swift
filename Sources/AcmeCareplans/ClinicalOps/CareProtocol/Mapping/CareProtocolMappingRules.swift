import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol mapping must pass. Check returns its problems, or none.
    protocol CareProtocolMappingRule {
        func check(_ item: CareProtocolMapping) -> [String]
    }

    final class CareProtocolMappingQuantityRangeRule: CareProtocolMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolMapping) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolMappingDescriptionLengthRule: CareProtocolMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolMapping) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolMappingUpdatedAtRangeRule: CareProtocolMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolMapping) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol mapping.
    final class CareProtocolMappingValidator {
        var rules: [any CareProtocolMappingRule]

        init(rules: [any CareProtocolMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolMapping) -> [String] {
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

        func requireValid(_ item: CareProtocolMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolMapping]) -> [String: [String]] {
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

    static func defaultCareProtocolMappingValidator() -> CareProtocolMappingValidator {
        return CareProtocolMappingValidator(
            rules: [
                CareProtocolMappingQuantityRangeRule(min: 80, max: 120),
                CareProtocolMappingDescriptionLengthRule(maxLength: 32),
                CareProtocolMappingUpdatedAtRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
