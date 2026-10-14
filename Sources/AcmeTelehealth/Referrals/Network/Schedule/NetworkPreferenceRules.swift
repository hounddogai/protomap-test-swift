import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network preference must pass. Check returns its problems, or none.
    protocol NetworkPreferenceRule {
        func check(_ item: NetworkPreference) -> [String]
    }

    final class NetworkPreferenceStartsAtRangeRule: NetworkPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkPreference) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkPreferenceMaximumRangeRule: NetworkPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkPreference) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkPreferenceCodePrefixRule: NetworkPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: NetworkPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class NetworkPreferenceQuantityRangeRule: NetworkPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkPreference) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class NetworkPreferenceArchivedGuardRule: NetworkPreferenceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: NetworkPreference) -> [String] {
            if item.archived && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class NetworkPreferenceLabelLengthRule: NetworkPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network preference.
    final class NetworkPreferenceValidator {
        var rules: [any NetworkPreferenceRule]

        init(rules: [any NetworkPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkPreference) -> [String] {
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

        func requireValid(_ item: NetworkPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkPreference]) -> [String: [String]] {
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

    static func defaultNetworkPreferenceValidator() -> NetworkPreferenceValidator {
        return NetworkPreferenceValidator(
            rules: [
                NetworkPreferenceStartsAtRangeRule(min: 3600, max: 86400),
                NetworkPreferenceMaximumRangeRule(min: 4.8, max: 4726.2),
                NetworkPreferenceCodePrefixRule(prefix: "ACM"),
                NetworkPreferenceQuantityRangeRule(min: 16, max: 80),
                NetworkPreferenceArchivedGuardRule(limit: 3.0),
                NetworkPreferenceLabelLengthRule(maxLength: 80),
            ]
        )
    }
}
