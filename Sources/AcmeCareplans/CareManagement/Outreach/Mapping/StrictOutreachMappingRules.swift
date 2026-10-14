import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a strict outreach mapping must pass. Check returns its problems, or none.
    protocol StrictOutreachMappingRule {
        func check(_ item: StrictOutreachMapping) -> [String]
    }

    final class StrictOutreachMappingRequiredChecksumRule: StrictOutreachMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOutreachMapping) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictOutreachMappingDiscountRangeRule: StrictOutreachMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictOutreachMapping) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictOutreachMappingAllowedChecksumRule: StrictOutreachMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictOutreachMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is blocked"]
            }
            return []
        }
    }

    final class StrictOutreachMappingCodeLengthRule: StrictOutreachMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictOutreachMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictOutreachMappingRequiredSegmentRule: StrictOutreachMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOutreachMapping) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictOutreachMappingChecksumLengthRule: StrictOutreachMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictOutreachMapping) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict outreach mapping.
    final class StrictOutreachMappingValidator {
        var rules: [any StrictOutreachMappingRule]

        init(rules: [any StrictOutreachMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictOutreachMapping) -> [String] {
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

        func requireValid(_ item: StrictOutreachMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictOutreachMapping]) -> [String: [String]] {
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

    static func defaultStrictOutreachMappingValidator() -> StrictOutreachMappingValidator {
        return StrictOutreachMappingValidator(
            rules: [
                StrictOutreachMappingRequiredChecksumRule(message: "strict outreach mapping needs an entry"),
                StrictOutreachMappingDiscountRangeRule(min: 8.9, max: 1606.7),
                StrictOutreachMappingAllowedChecksumRule(allowed: ["weighted", "legacy", "seasonal"]),
                StrictOutreachMappingCodeLengthRule(maxLength: 1000),
                StrictOutreachMappingRequiredSegmentRule(message: "strict outreach mapping needs an entry"),
                StrictOutreachMappingChecksumLengthRule(maxLength: 86400),
            ]
        )
    }
}
