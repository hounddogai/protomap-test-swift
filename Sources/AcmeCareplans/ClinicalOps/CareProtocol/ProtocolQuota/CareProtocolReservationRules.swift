import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol reservation must pass. Check returns its problems, or none.
    protocol CareProtocolReservationRule {
        func check(_ item: CareProtocolReservation) -> [String]
    }

    final class CareProtocolReservationApprovedGuardRule: CareProtocolReservationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CareProtocolReservation) -> [String] {
            if item.approved && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class CareProtocolReservationCreatedAtRangeRule: CareProtocolReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolReservation) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolReservationRequiredDescriptionRule: CareProtocolReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolReservation) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolReservationChecksumLengthRule: CareProtocolReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolReservation) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolReservationRequiredCodeRule: CareProtocolReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolReservationDescriptionLengthRule: CareProtocolReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolReservation) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol reservation.
    final class CareProtocolReservationValidator {
        var rules: [any CareProtocolReservationRule]

        init(rules: [any CareProtocolReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolReservation]) -> [String: [String]] {
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

    static func defaultCareProtocolReservationValidator() -> CareProtocolReservationValidator {
        return CareProtocolReservationValidator(
            rules: [
                CareProtocolReservationApprovedGuardRule(limit: 32),
                CareProtocolReservationCreatedAtRangeRule(min: 64, max: 120),
                CareProtocolReservationRequiredDescriptionRule(message: "care protocol reservation needs an entry"),
                CareProtocolReservationChecksumLengthRule(maxLength: 120),
                CareProtocolReservationRequiredCodeRule(message: "care protocol reservation needs this field"),
                CareProtocolReservationDescriptionLengthRule(maxLength: 86400),
            ]
        )
    }
}
