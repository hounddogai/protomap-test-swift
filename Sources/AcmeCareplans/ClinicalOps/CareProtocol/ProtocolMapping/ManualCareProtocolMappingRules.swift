import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual care protocol mapping must pass. Check returns its problems, or none.
    protocol ManualCareProtocolMappingRule {
        func check(_ item: ManualCareProtocolMapping) -> [String]
    }

    final class ManualCareProtocolMappingNameLengthRule: ManualCareProtocolMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareProtocolMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareProtocolMappingEndsAtRangeRule: ManualCareProtocolMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualCareProtocolMapping) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualCareProtocolMappingReviewerLengthRule: ManualCareProtocolMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareProtocolMapping) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual care protocol mapping.
    final class ManualCareProtocolMappingValidator {
        var rules: [any ManualCareProtocolMappingRule]

        init(rules: [any ManualCareProtocolMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCareProtocolMapping) -> [String] {
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

        func requireValid(_ item: ManualCareProtocolMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCareProtocolMapping]) -> [String: [String]] {
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

    static func defaultManualCareProtocolMappingValidator() -> ManualCareProtocolMappingValidator {
        return ManualCareProtocolMappingValidator(
            rules: [
                ManualCareProtocolMappingNameLengthRule(maxLength: 64),
                ManualCareProtocolMappingEndsAtRangeRule(min: 16, max: 255),
                ManualCareProtocolMappingReviewerLengthRule(maxLength: 120),
            ]
        )
    }
}
