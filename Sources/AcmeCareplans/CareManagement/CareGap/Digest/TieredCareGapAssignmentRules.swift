import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered care gap assignment must pass. Check returns its problems, or none.
    protocol TieredCareGapAssignmentRule {
        func check(_ item: TieredCareGapAssignment) -> [String]
    }

    final class TieredCareGapAssignmentFacilityLengthRule: TieredCareGapAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareGapAssignment) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCareGapAssignmentAllowedCodeRule: TieredCareGapAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredCareGapAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class TieredCareGapAssignmentRequiredCodeRule: TieredCareGapAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareGapAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered care gap assignment.
    final class TieredCareGapAssignmentValidator {
        var rules: [any TieredCareGapAssignmentRule]

        init(rules: [any TieredCareGapAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCareGapAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredCareGapAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCareGapAssignment]) -> [String: [String]] {
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

    static func defaultTieredCareGapAssignmentValidator() -> TieredCareGapAssignmentValidator {
        return TieredCareGapAssignmentValidator(
            rules: [
                TieredCareGapAssignmentFacilityLengthRule(maxLength: 3600),
                TieredCareGapAssignmentAllowedCodeRule(allowed: ["fallback"]),
                TieredCareGapAssignmentRequiredCodeRule(message: "tiered care gap assignment needs this field"),
            ]
        )
    }
}
