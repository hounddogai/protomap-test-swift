import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional inventory request must pass. Check returns its problems, or none.
    protocol RegionalInventoryRequestRule {
        func check(_ item: RegionalInventoryRequest) -> [String]
    }

    final class RegionalInventoryRequestTitleLengthRule: RegionalInventoryRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalInventoryRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalInventoryRequestCodeLengthRule: RegionalInventoryRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalInventoryRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalInventoryRequestAllowedTitleRule: RegionalInventoryRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalInventoryRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    final class RegionalInventoryRequestExpiresAtRangeRule: RegionalInventoryRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalInventoryRequest) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalInventoryRequestRequiredSpecialtyRule: RegionalInventoryRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalInventoryRequest) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional inventory request.
    final class RegionalInventoryRequestValidator {
        var rules: [any RegionalInventoryRequestRule]

        init(rules: [any RegionalInventoryRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalInventoryRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalInventoryRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalInventoryRequest]) -> [String: [String]] {
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

    static func defaultRegionalInventoryRequestValidator() -> RegionalInventoryRequestValidator {
        return RegionalInventoryRequestValidator(
            rules: [
                RegionalInventoryRequestTitleLengthRule(maxLength: 80),
                RegionalInventoryRequestCodeLengthRule(maxLength: 16),
                RegionalInventoryRequestAllowedTitleRule(allowed: []),
                RegionalInventoryRequestExpiresAtRangeRule(min: 1000, max: 3600),
                RegionalInventoryRequestRequiredSpecialtyRule(message: "regional inventory request needs this field"),
            ]
        )
    }
}
