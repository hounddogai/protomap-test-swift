import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled network bundle must pass. Check returns its problems, or none.
    protocol ScheduledNetworkBundleRule {
        func check(_ item: ScheduledNetworkBundle) -> [String]
    }

    final class ScheduledNetworkBundleCodePrefixRule: ScheduledNetworkBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledNetworkBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledNetworkBundleRequiredLabelRule: ScheduledNetworkBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledNetworkBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledNetworkBundleRequiredCodeRule: ScheduledNetworkBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledNetworkBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledNetworkBundleRequiredBedRule: ScheduledNetworkBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledNetworkBundle) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledNetworkBundleAllowedCodeRule: ScheduledNetworkBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledNetworkBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class ScheduledNetworkBundleWindowDaysRangeRule: ScheduledNetworkBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledNetworkBundle) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled network bundle.
    final class ScheduledNetworkBundleValidator {
        var rules: [any ScheduledNetworkBundleRule]

        init(rules: [any ScheduledNetworkBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledNetworkBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledNetworkBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledNetworkBundle]) -> [String: [String]] {
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

    static func defaultScheduledNetworkBundleValidator() -> ScheduledNetworkBundleValidator {
        return ScheduledNetworkBundleValidator(
            rules: [
                ScheduledNetworkBundleCodePrefixRule(prefix: "REF"),
                ScheduledNetworkBundleRequiredLabelRule(message: "scheduled network bundle needs this field"),
                ScheduledNetworkBundleRequiredCodeRule(message: "scheduled network bundle needs a value"),
                ScheduledNetworkBundleRequiredBedRule(message: "scheduled network bundle needs a value"),
                ScheduledNetworkBundleAllowedCodeRule(allowed: ["primary", "regional", "primary"]),
                ScheduledNetworkBundleWindowDaysRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
