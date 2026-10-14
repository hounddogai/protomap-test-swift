import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network agreement must pass. Check returns its problems, or none.
    protocol NetworkAgreementRule {
        func check(_ item: NetworkAgreement) -> [String]
    }

    final class NetworkAgreementRequiredClinicianIDRule: NetworkAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkAgreement) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkAgreementExpiresAtRangeRule: NetworkAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkAgreement) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkAgreementLabelLengthRule: NetworkAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkAgreement) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkAgreementAllowedClinicianIDRule: NetworkAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: NetworkAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a network agreement.
    final class NetworkAgreementValidator {
        var rules: [any NetworkAgreementRule]

        init(rules: [any NetworkAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkAgreement]) -> [String: [String]] {
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

    static func defaultNetworkAgreementValidator() -> NetworkAgreementValidator {
        return NetworkAgreementValidator(
            rules: [
                NetworkAgreementRequiredClinicianIDRule(message: "network agreement needs this field"),
                NetworkAgreementExpiresAtRangeRule(min: 80, max: 1000),
                NetworkAgreementLabelLengthRule(maxLength: 255),
                NetworkAgreementAllowedClinicianIDRule(allowed: []),
            ]
        )
    }
}
