import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure threshold must pass. Check returns its problems, or none.
    protocol DisclosureThresholdRule {
        func check(_ item: DisclosureThreshold) -> [String]
    }

    final class DisclosureThresholdNameLengthRule: DisclosureThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureThresholdRequiredFacilityRule: DisclosureThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureThreshold) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureThresholdCodePrefixRule: DisclosureThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DisclosureThresholdVisitMinutesRangeRule: DisclosureThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureThreshold) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DisclosureThresholdRequiredCodeRule: DisclosureThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure threshold.
    final class DisclosureThresholdValidator {
        var rules: [any DisclosureThresholdRule]

        init(rules: [any DisclosureThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureThreshold) -> [String] {
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

        func requireValid(_ item: DisclosureThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureThreshold]) -> [String: [String]] {
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

    static func defaultDisclosureThresholdValidator() -> DisclosureThresholdValidator {
        return DisclosureThresholdValidator(
            rules: [
                DisclosureThresholdNameLengthRule(maxLength: 16),
                DisclosureThresholdRequiredFacilityRule(message: "disclosure threshold needs this field"),
                DisclosureThresholdCodePrefixRule(prefix: "ACM"),
                DisclosureThresholdVisitMinutesRangeRule(min: 3600, max: 3600),
                DisclosureThresholdRequiredCodeRule(message: "disclosure threshold needs an entry"),
            ]
        )
    }
}
