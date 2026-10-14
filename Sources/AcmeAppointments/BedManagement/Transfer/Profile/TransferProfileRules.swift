import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer profile must pass. Check returns its problems, or none.
    protocol TransferProfileRule {
        func check(_ item: TransferProfile) -> [String]
    }

    final class TransferProfileSpecialtyLengthRule: TransferProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferProfile) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferProfileRequiredProcedureCodeRule: TransferProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferProfile) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferProfileDiscountRangeRule: TransferProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferProfile) -> [String] {
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

    final class TransferProfileFloorValueRangeRule: TransferProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferProfile) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferProfileRequiredLabelRule: TransferProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferProfile) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferProfileRequiredSpecialtyRule: TransferProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferProfile) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer profile.
    final class TransferProfileValidator {
        var rules: [any TransferProfileRule]

        init(rules: [any TransferProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferProfile) -> [String] {
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

        func requireValid(_ item: TransferProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferProfile]) -> [String: [String]] {
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

    static func defaultTransferProfileValidator() -> TransferProfileValidator {
        return TransferProfileValidator(
            rules: [
                TransferProfileSpecialtyLengthRule(maxLength: 16),
                TransferProfileRequiredProcedureCodeRule(message: "transfer profile needs a value"),
                TransferProfileDiscountRangeRule(min: 6.0, max: 199.1),
                TransferProfileFloorValueRangeRule(min: 2.2, max: 332.5),
                TransferProfileRequiredLabelRule(message: "transfer profile needs an entry"),
                TransferProfileRequiredSpecialtyRule(message: "transfer profile needs an entry"),
            ]
        )
    }
}
