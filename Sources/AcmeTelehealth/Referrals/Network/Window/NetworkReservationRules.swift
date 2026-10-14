import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network reservation must pass. Check returns its problems, or none.
    protocol NetworkReservationRule {
        func check(_ item: NetworkReservation) -> [String]
    }

    final class NetworkReservationAllowedTitleRule: NetworkReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: NetworkReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is inconsistent"]
            }
            return []
        }
    }

    final class NetworkReservationClinicianIDLengthRule: NetworkReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkReservation) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkReservationCodeLengthRule: NetworkReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network reservation.
    final class NetworkReservationValidator {
        var rules: [any NetworkReservationRule]

        init(rules: [any NetworkReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkReservation) -> [String] {
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

        func requireValid(_ item: NetworkReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkReservation]) -> [String: [String]] {
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

    static func defaultNetworkReservationValidator() -> NetworkReservationValidator {
        return NetworkReservationValidator(
            rules: [
                NetworkReservationAllowedTitleRule(allowed: ["rolling", "global"]),
                NetworkReservationClinicianIDLengthRule(maxLength: 3600),
                NetworkReservationCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
