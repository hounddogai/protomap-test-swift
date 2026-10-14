import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped claim forecast must pass. Check returns its problems, or none.
    protocol CappedClaimForecastRule {
        func check(_ item: CappedClaimForecast) -> [String]
    }

    final class CappedClaimForecastAllowedClinicianIDRule: CappedClaimForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedClaimForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is stale"]
            }
            return []
        }
    }

    final class CappedClaimForecastRevisionRangeRule: CappedClaimForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedClaimForecast) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedClaimForecastRequiredChecksumRule: CappedClaimForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedClaimForecast) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedClaimForecastCodeLengthRule: CappedClaimForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClaimForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped claim forecast.
    final class CappedClaimForecastValidator {
        var rules: [any CappedClaimForecastRule]

        init(rules: [any CappedClaimForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedClaimForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedClaimForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedClaimForecast]) -> [String: [String]] {
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

    static func defaultCappedClaimForecastValidator() -> CappedClaimForecastValidator {
        return CappedClaimForecastValidator(
            rules: [
                CappedClaimForecastAllowedClinicianIDRule(allowed: ["batched", "tiered"]),
                CappedClaimForecastRevisionRangeRule(min: 64, max: 120),
                CappedClaimForecastRequiredChecksumRule(message: "capped claim forecast needs a value"),
                CappedClaimForecastCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
