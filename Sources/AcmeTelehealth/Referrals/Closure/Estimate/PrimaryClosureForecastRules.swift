import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary closure forecast must pass. Check returns its problems, or none.
    protocol PrimaryClosureForecastRule {
        func check(_ item: PrimaryClosureForecast) -> [String]
    }

    final class PrimaryClosureForecastPhoneLengthRule: PrimaryClosureForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryClosureForecast) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryClosureForecastRequiredClinicianIDRule: PrimaryClosureForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryClosureForecast) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryClosureForecastAllowedClinicianIDRule: PrimaryClosureForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryClosureForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is too long"]
            }
            return []
        }
    }

    final class PrimaryClosureForecastRequiredCodeRule: PrimaryClosureForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryClosureForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryClosureForecastClinicianIDLengthRule: PrimaryClosureForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryClosureForecast) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryClosureForecastCodeLengthRule: PrimaryClosureForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryClosureForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary closure forecast.
    final class PrimaryClosureForecastValidator {
        var rules: [any PrimaryClosureForecastRule]

        init(rules: [any PrimaryClosureForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryClosureForecast) -> [String] {
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

        func requireValid(_ item: PrimaryClosureForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryClosureForecast]) -> [String: [String]] {
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

    static func defaultPrimaryClosureForecastValidator() -> PrimaryClosureForecastValidator {
        return PrimaryClosureForecastValidator(
            rules: [
                PrimaryClosureForecastPhoneLengthRule(maxLength: 64),
                PrimaryClosureForecastRequiredClinicianIDRule(message: "primary closure forecast needs an entry"),
                PrimaryClosureForecastAllowedClinicianIDRule(allowed: ["adaptive"]),
                PrimaryClosureForecastRequiredCodeRule(message: "primary closure forecast needs this field"),
                PrimaryClosureForecastClinicianIDLengthRule(maxLength: 120),
                PrimaryClosureForecastCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
