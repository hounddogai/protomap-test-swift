import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling priority reservation must pass. Check returns its problems, or none.
    protocol RollingPriorityReservationRule {
        func check(_ item: RollingPriorityReservation) -> [String]
    }

    final class RollingPriorityReservationRequiredCodeRule: RollingPriorityReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingPriorityReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingPriorityReservationAllowedNameRule: RollingPriorityReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingPriorityReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class RollingPriorityReservationBatchSizeRangeRule: RollingPriorityReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingPriorityReservation) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingPriorityReservationNameLengthRule: RollingPriorityReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPriorityReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingPriorityReservationCodePrefixRule: RollingPriorityReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingPriorityReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling priority reservation.
    final class RollingPriorityReservationValidator {
        var rules: [any RollingPriorityReservationRule]

        init(rules: [any RollingPriorityReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingPriorityReservation) -> [String] {
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

        func requireValid(_ item: RollingPriorityReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingPriorityReservation]) -> [String: [String]] {
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

    static func defaultRollingPriorityReservationValidator() -> RollingPriorityReservationValidator {
        return RollingPriorityReservationValidator(
            rules: [
                RollingPriorityReservationRequiredCodeRule(message: "rolling priority reservation needs an entry"),
                RollingPriorityReservationAllowedNameRule(allowed: ["strict", "primary"]),
                RollingPriorityReservationBatchSizeRangeRule(min: 16, max: 64),
                RollingPriorityReservationNameLengthRule(maxLength: 32),
                RollingPriorityReservationCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
