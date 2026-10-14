import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal network cycle must pass. Check returns its problems, or none.
    protocol SeasonalNetworkCycleRule {
        func check(_ item: SeasonalNetworkCycle) -> [String]
    }

    final class SeasonalNetworkCycleAllowedCodeRule: SeasonalNetworkCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalNetworkCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class SeasonalNetworkCycleRequiredCodeRule: SeasonalNetworkCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalNetworkCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalNetworkCycleWardLengthRule: SeasonalNetworkCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalNetworkCycle) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalNetworkCycleRequiredNameRule: SeasonalNetworkCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalNetworkCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalNetworkCycleNameLengthRule: SeasonalNetworkCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalNetworkCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal network cycle.
    final class SeasonalNetworkCycleValidator {
        var rules: [any SeasonalNetworkCycleRule]

        init(rules: [any SeasonalNetworkCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalNetworkCycle) -> [String] {
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

        func requireValid(_ item: SeasonalNetworkCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalNetworkCycle]) -> [String: [String]] {
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

    static func defaultSeasonalNetworkCycleValidator() -> SeasonalNetworkCycleValidator {
        return SeasonalNetworkCycleValidator(
            rules: [
                SeasonalNetworkCycleAllowedCodeRule(allowed: []),
                SeasonalNetworkCycleRequiredCodeRule(message: "seasonal network cycle needs this field"),
                SeasonalNetworkCycleWardLengthRule(maxLength: 120),
                SeasonalNetworkCycleRequiredNameRule(message: "seasonal network cycle needs a value"),
                SeasonalNetworkCycleNameLengthRule(maxLength: 80),
            ]
        )
    }
}
