import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure reservation must pass. Check returns its problems, or none.
    protocol DisclosureReservationRule {
        func check(_ item: DisclosureReservation) -> [String]
    }

    final class DisclosureReservationSourceLengthRule: DisclosureReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureReservation) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureReservationUpdatedAtRangeRule: DisclosureReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureReservation) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureReservationCodeLengthRule: DisclosureReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureReservationAllowedTitleRule: DisclosureReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosureReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    final class DisclosureReservationVersionRangeRule: DisclosureReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureReservation) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DisclosureReservationRequiredTitleRule: DisclosureReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure reservation.
    final class DisclosureReservationValidator {
        var rules: [any DisclosureReservationRule]

        init(rules: [any DisclosureReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureReservation]) -> [String: [String]] {
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

    static func defaultDisclosureReservationValidator() -> DisclosureReservationValidator {
        return DisclosureReservationValidator(
            rules: [
                DisclosureReservationSourceLengthRule(maxLength: 255),
                DisclosureReservationUpdatedAtRangeRule(min: 32, max: 86400),
                DisclosureReservationCodeLengthRule(maxLength: 80),
                DisclosureReservationAllowedTitleRule(allowed: ["fallback", "pending"]),
                DisclosureReservationVersionRangeRule(min: 64, max: 64),
                DisclosureReservationRequiredTitleRule(message: "disclosure reservation needs this field"),
            ]
        )
    }
}
