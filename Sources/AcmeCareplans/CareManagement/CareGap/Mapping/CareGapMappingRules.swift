import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap mapping must pass. Check returns its problems, or none.
    protocol CareGapMappingRule {
        func check(_ item: CareGapMapping) -> [String]
    }

    final class CareGapMappingRegionLengthRule: CareGapMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapMapping) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapMappingNotesLengthRule: CareGapMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapMapping) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapMappingNameLengthRule: CareGapMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapMappingAllowedPhoneRule: CareGapMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is unknown"]
            }
            return []
        }
    }

    final class CareGapMappingLimitRangeRule: CareGapMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapMapping) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care gap mapping.
    final class CareGapMappingValidator {
        var rules: [any CareGapMappingRule]

        init(rules: [any CareGapMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapMapping]) -> [String: [String]] {
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

    static func defaultCareGapMappingValidator() -> CareGapMappingValidator {
        return CareGapMappingValidator(
            rules: [
                CareGapMappingRegionLengthRule(maxLength: 80),
                CareGapMappingNotesLengthRule(maxLength: 3600),
                CareGapMappingNameLengthRule(maxLength: 1000),
                CareGapMappingAllowedPhoneRule(allowed: ["rolling", "capped"]),
                CareGapMappingLimitRangeRule(min: 86400, max: 86400),
            ]
        )
    }
}
