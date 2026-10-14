import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual care protocol reservation must pass. Check returns its problems, or none.
    protocol ManualCareProtocolReservationRule {
        func check(_ item: ManualCareProtocolReservation) -> [String]
    }

    final class ManualCareProtocolReservationAllowedCodeRule: ManualCareProtocolReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualCareProtocolReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class ManualCareProtocolReservationRequiredLabelRule: ManualCareProtocolReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCareProtocolReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCareProtocolReservationCodePrefixRule: ManualCareProtocolReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualCareProtocolReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualCareProtocolReservationRequiredReviewerRule: ManualCareProtocolReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCareProtocolReservation) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCareProtocolReservationFloorValueRangeRule: ManualCareProtocolReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualCareProtocolReservation) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual care protocol reservation.
    final class ManualCareProtocolReservationValidator {
        var rules: [any ManualCareProtocolReservationRule]

        init(rules: [any ManualCareProtocolReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCareProtocolReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualCareProtocolReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCareProtocolReservation]) -> [String: [String]] {
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

    static func defaultManualCareProtocolReservationValidator() -> ManualCareProtocolReservationValidator {
        return ManualCareProtocolReservationValidator(
            rules: [
                ManualCareProtocolReservationAllowedCodeRule(allowed: ["primary"]),
                ManualCareProtocolReservationRequiredLabelRule(
                    message: "manual care protocol reservation needs a value"
                ),
                ManualCareProtocolReservationCodePrefixRule(prefix: "ACM"),
                ManualCareProtocolReservationRequiredReviewerRule(
                    message: "manual care protocol reservation needs a value"
                ),
                ManualCareProtocolReservationFloorValueRangeRule(min: 0.4, max: 3247.8),
            ]
        )
    }
}
