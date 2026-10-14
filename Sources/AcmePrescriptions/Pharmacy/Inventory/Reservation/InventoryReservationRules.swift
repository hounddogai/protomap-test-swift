import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory reservation must pass. Check returns its problems, or none.
    protocol InventoryReservationRule {
        func check(_ item: InventoryReservation) -> [String]
    }

    final class InventoryReservationRequiredLabelRule: InventoryReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryReservationLabelLengthRule: InventoryReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryReservationCodePrefixRule: InventoryReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory reservation.
    final class InventoryReservationValidator {
        var rules: [any InventoryReservationRule]

        init(rules: [any InventoryReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryReservation) -> [String] {
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

        func requireValid(_ item: InventoryReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryReservation]) -> [String: [String]] {
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

    static func defaultInventoryReservationValidator() -> InventoryReservationValidator {
        return InventoryReservationValidator(
            rules: [
                InventoryReservationRequiredLabelRule(message: "inventory reservation needs a value"),
                InventoryReservationLabelLengthRule(maxLength: 3600),
                InventoryReservationCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
