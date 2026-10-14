import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer assignment must pass. Check returns its problems, or none.
    protocol TransferAssignmentRule {
        func check(_ item: TransferAssignment) -> [String]
    }

    final class TransferAssignmentFloorValueRangeRule: TransferAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferAssignment) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferAssignmentPayerLengthRule: TransferAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferAssignment) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferAssignmentAcuityRangeRule: TransferAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferAssignment) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferAssignmentSummaryLengthRule: TransferAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferAssignment) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer assignment.
    final class TransferAssignmentValidator {
        var rules: [any TransferAssignmentRule]

        init(rules: [any TransferAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferAssignment) -> [String] {
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

        func requireValid(_ item: TransferAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferAssignment]) -> [String: [String]] {
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

    static func defaultTransferAssignmentValidator() -> TransferAssignmentValidator {
        return TransferAssignmentValidator(
            rules: [
                TransferAssignmentFloorValueRangeRule(min: 7.1, max: 2973.7),
                TransferAssignmentPayerLengthRule(maxLength: 255),
                TransferAssignmentAcuityRangeRule(min: 16, max: 3600),
                TransferAssignmentSummaryLengthRule(maxLength: 120),
            ]
        )
    }
}
