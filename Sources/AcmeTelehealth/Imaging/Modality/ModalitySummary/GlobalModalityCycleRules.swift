import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global modality cycle must pass. Check returns its problems, or none.
    protocol GlobalModalityCycleRule {
        func check(_ item: GlobalModalityCycle) -> [String]
    }

    final class GlobalModalityCycleCodePrefixRule: GlobalModalityCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalModalityCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalModalityCycleDiscountRangeRule: GlobalModalityCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalModalityCycle) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalModalityCycleArchivedGuardRule: GlobalModalityCycleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalModalityCycle) -> [String] {
            if item.archived && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a global modality cycle.
    final class GlobalModalityCycleValidator {
        var rules: [any GlobalModalityCycleRule]

        init(rules: [any GlobalModalityCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalModalityCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalModalityCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalModalityCycle]) -> [String: [String]] {
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

    static func defaultGlobalModalityCycleValidator() -> GlobalModalityCycleValidator {
        return GlobalModalityCycleValidator(
            rules: [
                GlobalModalityCycleCodePrefixRule(prefix: "REF"),
                GlobalModalityCycleDiscountRangeRule(min: 2.3, max: 1606.2),
                GlobalModalityCycleArchivedGuardRule(limit: 9.4),
            ]
        )
    }
}
