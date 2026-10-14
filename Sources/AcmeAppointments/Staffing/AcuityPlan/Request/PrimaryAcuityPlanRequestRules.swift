import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary acuity plan request must pass. Check returns its problems, or none.
    protocol PrimaryAcuityPlanRequestRule {
        func check(_ item: PrimaryAcuityPlanRequest) -> [String]
    }

    final class PrimaryAcuityPlanRequestExpiresAtRangeRule: PrimaryAcuityPlanRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryAcuityPlanRequest) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanRequestRequiredPatientRefRule: PrimaryAcuityPlanRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAcuityPlanRequest) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanRequestRequiredCodeRule: PrimaryAcuityPlanRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAcuityPlanRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanRequestCodePrefixRule: PrimaryAcuityPlanRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryAcuityPlanRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanRequestCodeLengthRule: PrimaryAcuityPlanRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAcuityPlanRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanRequestAllowedCodeRule: PrimaryAcuityPlanRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryAcuityPlanRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a primary acuity plan request.
    final class PrimaryAcuityPlanRequestValidator {
        var rules: [any PrimaryAcuityPlanRequestRule]

        init(rules: [any PrimaryAcuityPlanRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAcuityPlanRequest) -> [String] {
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

        func requireValid(_ item: PrimaryAcuityPlanRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAcuityPlanRequest]) -> [String: [String]] {
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

    static func defaultPrimaryAcuityPlanRequestValidator() -> PrimaryAcuityPlanRequestValidator {
        return PrimaryAcuityPlanRequestValidator(
            rules: [
                PrimaryAcuityPlanRequestExpiresAtRangeRule(min: 16, max: 32),
                PrimaryAcuityPlanRequestRequiredPatientRefRule(message: "primary acuity plan request needs a value"),
                PrimaryAcuityPlanRequestRequiredCodeRule(message: "primary acuity plan request needs a value"),
                PrimaryAcuityPlanRequestCodePrefixRule(prefix: "Q"),
                PrimaryAcuityPlanRequestCodeLengthRule(maxLength: 120),
                PrimaryAcuityPlanRequestAllowedCodeRule(allowed: ["rolling", "fallback"]),
            ]
        )
    }
}
