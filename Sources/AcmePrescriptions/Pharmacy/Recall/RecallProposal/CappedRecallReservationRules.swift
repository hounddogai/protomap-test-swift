import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped recall reservation must pass. Check returns its problems, or none.
    protocol CappedRecallReservationRule {
        func check(_ item: CappedRecallReservation) -> [String]
    }

    final class CappedRecallReservationCodePrefixRule: CappedRecallReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedRecallReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedRecallReservationChecksumLengthRule: CappedRecallReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRecallReservation) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRecallReservationRequiredNameRule: CappedRecallReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRecallReservation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped recall reservation.
    final class CappedRecallReservationValidator {
        var rules: [any CappedRecallReservationRule]

        init(rules: [any CappedRecallReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRecallReservation) -> [String] {
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

        func requireValid(_ item: CappedRecallReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRecallReservation]) -> [String: [String]] {
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

    static func defaultCappedRecallReservationValidator() -> CappedRecallReservationValidator {
        return CappedRecallReservationValidator(
            rules: [
                CappedRecallReservationCodePrefixRule(prefix: "X"),
                CappedRecallReservationChecksumLengthRule(maxLength: 16),
                CappedRecallReservationRequiredNameRule(message: "capped recall reservation needs an entry"),
            ]
        )
    }
}
