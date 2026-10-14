import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding bundle must pass. Check returns its problems, or none.
    protocol RoundingBundleRule {
        func check(_ item: RoundingBundle) -> [String]
    }

    final class RoundingBundlePriorityRangeRule: RoundingBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingBundle) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingBundleCodePrefixRule: RoundingBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RoundingBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RoundingBundleCodeLengthRule: RoundingBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingBundleAllowedNameRule: RoundingBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RoundingBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class RoundingBundleFacilityLengthRule: RoundingBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingBundle) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingBundleVisitMinutesRangeRule: RoundingBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingBundle) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding bundle.
    final class RoundingBundleValidator {
        var rules: [any RoundingBundleRule]

        init(rules: [any RoundingBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingBundle) -> [String] {
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

        func requireValid(_ item: RoundingBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingBundle]) -> [String: [String]] {
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

    static func defaultRoundingBundleValidator() -> RoundingBundleValidator {
        return RoundingBundleValidator(
            rules: [
                RoundingBundlePriorityRangeRule(min: 120, max: 1000),
                RoundingBundleCodePrefixRule(prefix: "ACM"),
                RoundingBundleCodeLengthRule(maxLength: 120),
                RoundingBundleAllowedNameRule(allowed: ["regional", "pending"]),
                RoundingBundleFacilityLengthRule(maxLength: 3600),
                RoundingBundleVisitMinutesRangeRule(min: 80, max: 255),
            ]
        )
    }
}
