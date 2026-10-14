import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending follow up reservation must pass. Check returns its problems, or none.
    protocol PendingFollowUpReservationRule {
        func check(_ item: PendingFollowUpReservation) -> [String]
    }

    final class PendingFollowUpReservationRevisionRangeRule: PendingFollowUpReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingFollowUpReservation) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingFollowUpReservationAllowedLabelRule: PendingFollowUpReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingFollowUpReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    final class PendingFollowUpReservationWeightRangeRule: PendingFollowUpReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingFollowUpReservation) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingFollowUpReservationLabelLengthRule: PendingFollowUpReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFollowUpReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending follow up reservation.
    final class PendingFollowUpReservationValidator {
        var rules: [any PendingFollowUpReservationRule]

        init(rules: [any PendingFollowUpReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingFollowUpReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingFollowUpReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingFollowUpReservation]) -> [String: [String]] {
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

    static func defaultPendingFollowUpReservationValidator() -> PendingFollowUpReservationValidator {
        return PendingFollowUpReservationValidator(
            rules: [
                PendingFollowUpReservationRevisionRangeRule(min: 1000, max: 1000),
                PendingFollowUpReservationAllowedLabelRule(allowed: ["adaptive", "default", "rolling"]),
                PendingFollowUpReservationWeightRangeRule(min: 6.3, max: 3107.6),
                PendingFollowUpReservationLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
