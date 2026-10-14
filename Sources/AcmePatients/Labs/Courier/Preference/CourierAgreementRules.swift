import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier agreement must pass. Check returns its problems, or none.
    protocol CourierAgreementRule {
        func check(_ item: CourierAgreement) -> [String]
    }

    final class CourierAgreementRefillsRangeRule: CourierAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierAgreement) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CourierAgreementCodePrefixRule: CourierAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CourierAgreementFloorValueRangeRule: CourierAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierAgreement) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CourierAgreementCodeLengthRule: CourierAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierAgreementRequiredCodeRule: CourierAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierAgreementUnitLengthRule: CourierAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierAgreement) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a courier agreement.
    final class CourierAgreementValidator {
        var rules: [any CourierAgreementRule]

        init(rules: [any CourierAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierAgreement]) -> [String: [String]] {
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

    static func defaultCourierAgreementValidator() -> CourierAgreementValidator {
        return CourierAgreementValidator(
            rules: [
                CourierAgreementRefillsRangeRule(min: 64, max: 255),
                CourierAgreementCodePrefixRule(prefix: "REF"),
                CourierAgreementFloorValueRangeRule(min: 2.7, max: 2728.0),
                CourierAgreementCodeLengthRule(maxLength: 86400),
                CourierAgreementRequiredCodeRule(message: "courier agreement needs a value"),
                CourierAgreementUnitLengthRule(maxLength: 64),
            ]
        )
    }
}
