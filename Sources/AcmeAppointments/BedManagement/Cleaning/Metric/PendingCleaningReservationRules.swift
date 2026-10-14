import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending cleaning reservation must pass. Check returns its problems, or none.
    protocol PendingCleaningReservationRule {
        func check(_ item: PendingCleaningReservation) -> [String]
    }

    final class PendingCleaningReservationOwnerIDLengthRule: PendingCleaningReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCleaningReservation) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCleaningReservationCodePrefixRule: PendingCleaningReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingCleaningReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingCleaningReservationApprovedGuardRule: PendingCleaningReservationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PendingCleaningReservation) -> [String] {
            if item.approved && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class PendingCleaningReservationAllowedTitleRule: PendingCleaningReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingCleaningReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class PendingCleaningReservationCodeLengthRule: PendingCleaningReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCleaningReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCleaningReservationRequiredOwnerIDRule: PendingCleaningReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCleaningReservation) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending cleaning reservation.
    final class PendingCleaningReservationValidator {
        var rules: [any PendingCleaningReservationRule]

        init(rules: [any PendingCleaningReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCleaningReservation) -> [String] {
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

        func requireValid(_ item: PendingCleaningReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCleaningReservation]) -> [String: [String]] {
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

    static func defaultPendingCleaningReservationValidator() -> PendingCleaningReservationValidator {
        return PendingCleaningReservationValidator(
            rules: [
                PendingCleaningReservationOwnerIDLengthRule(maxLength: 80),
                PendingCleaningReservationCodePrefixRule(prefix: "OPS"),
                PendingCleaningReservationApprovedGuardRule(limit: 5.0),
                PendingCleaningReservationAllowedTitleRule(allowed: ["global"]),
                PendingCleaningReservationCodeLengthRule(maxLength: 16),
                PendingCleaningReservationRequiredOwnerIDRule(
                    message: "pending cleaning reservation needs this field"
                ),
            ]
        )
    }
}
