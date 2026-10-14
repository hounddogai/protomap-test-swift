import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy reservation must pass. Check returns its problems, or none.
    protocol ProxyReservationRule {
        func check(_ item: ProxyReservation) -> [String]
    }

    final class ProxyReservationRequiredCodeRule: ProxyReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyReservationNameLengthRule: ProxyReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyReservationCodePrefixRule: ProxyReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy reservation.
    final class ProxyReservationValidator {
        var rules: [any ProxyReservationRule]

        init(rules: [any ProxyReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyReservation) -> [String] {
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

        func requireValid(_ item: ProxyReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyReservation]) -> [String: [String]] {
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

    static func defaultProxyReservationValidator() -> ProxyReservationValidator {
        return ProxyReservationValidator(
            rules: [
                ProxyReservationRequiredCodeRule(message: "proxy reservation needs this field"),
                ProxyReservationNameLengthRule(maxLength: 64),
                ProxyReservationCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
