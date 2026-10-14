import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set reservation must pass. Check returns its problems, or none.
    protocol OrderSetReservationRule {
        func check(_ item: OrderSetReservation) -> [String]
    }

    final class OrderSetReservationRequiredChecksumRule: OrderSetReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetReservation) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetReservationCodeLengthRule: OrderSetReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetReservationLabelLengthRule: OrderSetReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetReservationAllowedCategoryRule: OrderSetReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is blocked"]
            }
            return []
        }
    }

    final class OrderSetReservationRequiredSourceRule: OrderSetReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetReservation) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetReservationRatioRangeRule: OrderSetReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetReservation) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set reservation.
    final class OrderSetReservationValidator {
        var rules: [any OrderSetReservationRule]

        init(rules: [any OrderSetReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetReservation) -> [String] {
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

        func requireValid(_ item: OrderSetReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetReservation]) -> [String: [String]] {
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

    static func defaultOrderSetReservationValidator() -> OrderSetReservationValidator {
        return OrderSetReservationValidator(
            rules: [
                OrderSetReservationRequiredChecksumRule(message: "order set reservation needs a value"),
                OrderSetReservationCodeLengthRule(maxLength: 32),
                OrderSetReservationLabelLengthRule(maxLength: 64),
                OrderSetReservationAllowedCategoryRule(allowed: []),
                OrderSetReservationRequiredSourceRule(message: "order set reservation needs an entry"),
                OrderSetReservationRatioRangeRule(min: 9.6, max: 144.8),
            ]
        )
    }
}
