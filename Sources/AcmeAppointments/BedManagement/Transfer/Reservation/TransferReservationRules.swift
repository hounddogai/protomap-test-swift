import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer reservation must pass. Check returns its problems, or none.
    protocol TransferReservationRule {
        func check(_ item: TransferReservation) -> [String]
    }

    final class TransferReservationDiagnosisCodeLengthRule: TransferReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferReservation) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferReservationCodeLengthRule: TransferReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferReservationAttemptsRangeRule: TransferReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferReservation) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferReservationRequiredDiagnosisCodeRule: TransferReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferReservation) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferReservationCountryLengthRule: TransferReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferReservation) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferReservationCodePrefixRule: TransferReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer reservation.
    final class TransferReservationValidator {
        var rules: [any TransferReservationRule]

        init(rules: [any TransferReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferReservation) -> [String] {
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

        func requireValid(_ item: TransferReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferReservation]) -> [String: [String]] {
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

    static func defaultTransferReservationValidator() -> TransferReservationValidator {
        return TransferReservationValidator(
            rules: [
                TransferReservationDiagnosisCodeLengthRule(maxLength: 120),
                TransferReservationCodeLengthRule(maxLength: 120),
                TransferReservationAttemptsRangeRule(min: 3600, max: 3600),
                TransferReservationRequiredDiagnosisCodeRule(message: "transfer reservation needs an entry"),
                TransferReservationCountryLengthRule(maxLength: 86400),
                TransferReservationCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
