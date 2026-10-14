import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap allocation must pass. Check returns its problems, or none.
    protocol CareGapAllocationRule {
        func check(_ item: CareGapAllocation) -> [String]
    }

    final class CareGapAllocationCodePrefixRule: CareGapAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareGapAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareGapAllocationEncounterIDLengthRule: CareGapAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapAllocation) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapAllocationWardLengthRule: CareGapAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapAllocation) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap allocation.
    final class CareGapAllocationValidator {
        var rules: [any CareGapAllocationRule]

        init(rules: [any CareGapAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapAllocation) -> [String] {
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

        func requireValid(_ item: CareGapAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapAllocation]) -> [String: [String]] {
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

    static func defaultCareGapAllocationValidator() -> CareGapAllocationValidator {
        return CareGapAllocationValidator(
            rules: [
                CareGapAllocationCodePrefixRule(prefix: "ACM"),
                CareGapAllocationEncounterIDLengthRule(maxLength: 1000),
                CareGapAllocationWardLengthRule(maxLength: 16),
            ]
        )
    }
}
