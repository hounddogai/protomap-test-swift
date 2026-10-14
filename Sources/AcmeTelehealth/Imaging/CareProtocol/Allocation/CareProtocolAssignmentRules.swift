import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol assignment must pass. Check returns its problems, or none.
    protocol CareProtocolAssignmentRule {
        func check(_ item: CareProtocolAssignment) -> [String]
    }

    final class CareProtocolAssignmentApprovedGuardRule: CareProtocolAssignmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CareProtocolAssignment) -> [String] {
            if item.approved && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class CareProtocolAssignmentCodeLengthRule: CareProtocolAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolAssignmentLabelLengthRule: CareProtocolAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolAssignment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolAssignmentRequiredCodeRule: CareProtocolAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolAssignmentCopayRangeRule: CareProtocolAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolAssignment) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolAssignmentQuantityRangeRule: CareProtocolAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolAssignment) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care protocol assignment.
    final class CareProtocolAssignmentValidator {
        var rules: [any CareProtocolAssignmentRule]

        init(rules: [any CareProtocolAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolAssignment]) -> [String: [String]] {
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

    static func defaultCareProtocolAssignmentValidator() -> CareProtocolAssignmentValidator {
        return CareProtocolAssignmentValidator(
            rules: [
                CareProtocolAssignmentApprovedGuardRule(limit: 86400),
                CareProtocolAssignmentCodeLengthRule(maxLength: 80),
                CareProtocolAssignmentLabelLengthRule(maxLength: 64),
                CareProtocolAssignmentRequiredCodeRule(message: "care protocol assignment needs an entry"),
                CareProtocolAssignmentCopayRangeRule(min: 5.9, max: 974.7),
                CareProtocolAssignmentQuantityRangeRule(min: 16, max: 120),
            ]
        )
    }
}
