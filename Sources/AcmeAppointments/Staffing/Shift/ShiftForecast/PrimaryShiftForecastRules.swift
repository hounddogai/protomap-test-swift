import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary shift forecast must pass. Check returns its problems, or none.
    protocol PrimaryShiftForecastRule {
        func check(_ item: PrimaryShiftForecast) -> [String]
    }

    final class PrimaryShiftForecastArchivedGuardRule: PrimaryShiftForecastRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PrimaryShiftForecast) -> [String] {
            if item.archived && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class PrimaryShiftForecastLabelLengthRule: PrimaryShiftForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryShiftForecast) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryShiftForecastAllowedLabelRule: PrimaryShiftForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryShiftForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a primary shift forecast.
    final class PrimaryShiftForecastValidator {
        var rules: [any PrimaryShiftForecastRule]

        init(rules: [any PrimaryShiftForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryShiftForecast) -> [String] {
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

        func requireValid(_ item: PrimaryShiftForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryShiftForecast]) -> [String: [String]] {
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

    static func defaultPrimaryShiftForecastValidator() -> PrimaryShiftForecastValidator {
        return PrimaryShiftForecastValidator(
            rules: [
                PrimaryShiftForecastArchivedGuardRule(limit: 255),
                PrimaryShiftForecastLabelLengthRule(maxLength: 16),
                PrimaryShiftForecastAllowedLabelRule(allowed: ["seasonal", "rolling"]),
            ]
        )
    }
}
