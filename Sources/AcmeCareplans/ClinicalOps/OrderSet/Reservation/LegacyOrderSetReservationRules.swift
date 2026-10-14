import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy order set reservation must pass. Check returns its problems, or none.
    protocol LegacyOrderSetReservationRule {
        func check(_ item: LegacyOrderSetReservation) -> [String]
    }

    final class LegacyOrderSetReservationRequiredLabelRule: LegacyOrderSetReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyOrderSetReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyOrderSetReservationCodePrefixRule: LegacyOrderSetReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyOrderSetReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyOrderSetReservationAllowedLabelRule: LegacyOrderSetReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyOrderSetReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is below minimum"]
            }
            return []
        }
    }

    final class LegacyOrderSetReservationExternalRefLengthRule: LegacyOrderSetReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOrderSetReservation) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy order set reservation.
    final class LegacyOrderSetReservationValidator {
        var rules: [any LegacyOrderSetReservationRule]

        init(rules: [any LegacyOrderSetReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyOrderSetReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyOrderSetReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyOrderSetReservation]) -> [String: [String]] {
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

    static func defaultLegacyOrderSetReservationValidator() -> LegacyOrderSetReservationValidator {
        return LegacyOrderSetReservationValidator(
            rules: [
                LegacyOrderSetReservationRequiredLabelRule(message: "legacy order set reservation needs this field"),
                LegacyOrderSetReservationCodePrefixRule(prefix: "X"),
                LegacyOrderSetReservationAllowedLabelRule(allowed: []),
                LegacyOrderSetReservationExternalRefLengthRule(maxLength: 3600),
            ]
        )
    }
}
