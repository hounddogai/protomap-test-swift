import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched formulary reservation must pass. Check returns its problems, or none.
    protocol BatchedFormularyReservationRule {
        func check(_ item: BatchedFormularyReservation) -> [String]
    }

    final class BatchedFormularyReservationRequiredNameRule: BatchedFormularyReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedFormularyReservation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedFormularyReservationWeightRangeRule: BatchedFormularyReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedFormularyReservation) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedFormularyReservationCodePrefixRule: BatchedFormularyReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedFormularyReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedFormularyReservationChecksumLengthRule: BatchedFormularyReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedFormularyReservation) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedFormularyReservationAllowedNameRule: BatchedFormularyReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedFormularyReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a batched formulary reservation.
    final class BatchedFormularyReservationValidator {
        var rules: [any BatchedFormularyReservationRule]

        init(rules: [any BatchedFormularyReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedFormularyReservation) -> [String] {
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

        func requireValid(_ item: BatchedFormularyReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedFormularyReservation]) -> [String: [String]] {
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

    static func defaultBatchedFormularyReservationValidator() -> BatchedFormularyReservationValidator {
        return BatchedFormularyReservationValidator(
            rules: [
                BatchedFormularyReservationRequiredNameRule(message: "batched formulary reservation needs an entry"),
                BatchedFormularyReservationWeightRangeRule(min: 4.6, max: 4855.7),
                BatchedFormularyReservationCodePrefixRule(prefix: "Q"),
                BatchedFormularyReservationChecksumLengthRule(maxLength: 255),
                BatchedFormularyReservationAllowedNameRule(allowed: ["pending", "weighted", "default"]),
            ]
        )
    }
}
