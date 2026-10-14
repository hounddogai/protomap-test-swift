import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary read reservation must pass. Check returns its problems, or none.
    protocol PrimaryReadReservationRule {
        func check(_ item: PrimaryReadReservation) -> [String]
    }

    final class PrimaryReadReservationPhoneLengthRule: PrimaryReadReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryReadReservation) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryReadReservationApprovedGuardRule: PrimaryReadReservationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PrimaryReadReservation) -> [String] {
            if item.approved && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class PrimaryReadReservationRequiredTitleRule: PrimaryReadReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryReadReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryReadReservationRequiredCodeRule: PrimaryReadReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryReadReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryReadReservationAllowedChecksumRule: PrimaryReadReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryReadReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is duplicated"]
            }
            return []
        }
    }

    final class PrimaryReadReservationCodeLengthRule: PrimaryReadReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryReadReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary read reservation.
    final class PrimaryReadReservationValidator {
        var rules: [any PrimaryReadReservationRule]

        init(rules: [any PrimaryReadReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryReadReservation) -> [String] {
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

        func requireValid(_ item: PrimaryReadReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryReadReservation]) -> [String: [String]] {
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

    static func defaultPrimaryReadReservationValidator() -> PrimaryReadReservationValidator {
        return PrimaryReadReservationValidator(
            rules: [
                PrimaryReadReservationPhoneLengthRule(maxLength: 16),
                PrimaryReadReservationApprovedGuardRule(limit: 64),
                PrimaryReadReservationRequiredTitleRule(message: "primary read reservation needs an entry"),
                PrimaryReadReservationRequiredCodeRule(message: "primary read reservation needs a value"),
                PrimaryReadReservationAllowedChecksumRule(allowed: ["batched", "manual"]),
                PrimaryReadReservationCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
