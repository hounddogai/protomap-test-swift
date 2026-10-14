import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered priority reservation must pass. Check returns its problems, or none.
    protocol TieredPriorityReservationRule {
        func check(_ item: TieredPriorityReservation) -> [String]
    }

    final class TieredPriorityReservationRequiredTimezoneRule: TieredPriorityReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPriorityReservation) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredPriorityReservationCodeLengthRule: TieredPriorityReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPriorityReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPriorityReservationTitleLengthRule: TieredPriorityReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPriorityReservation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPriorityReservationAllowedTimezoneRule: TieredPriorityReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredPriorityReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is stale"]
            }
            return []
        }
    }

    final class TieredPriorityReservationCodePrefixRule: TieredPriorityReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredPriorityReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered priority reservation.
    final class TieredPriorityReservationValidator {
        var rules: [any TieredPriorityReservationRule]

        init(rules: [any TieredPriorityReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredPriorityReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredPriorityReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredPriorityReservation]) -> [String: [String]] {
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

    static func defaultTieredPriorityReservationValidator() -> TieredPriorityReservationValidator {
        return TieredPriorityReservationValidator(
            rules: [
                TieredPriorityReservationRequiredTimezoneRule(message: "tiered priority reservation needs a value"),
                TieredPriorityReservationCodeLengthRule(maxLength: 255),
                TieredPriorityReservationTitleLengthRule(maxLength: 120),
                TieredPriorityReservationAllowedTimezoneRule(allowed: []),
                TieredPriorityReservationCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
