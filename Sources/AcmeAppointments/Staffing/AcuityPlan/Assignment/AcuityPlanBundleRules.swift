import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan bundle must pass. Check returns its problems, or none.
    protocol AcuityPlanBundleRule {
        func check(_ item: AcuityPlanBundle) -> [String]
    }

    final class AcuityPlanBundleAcuityRangeRule: AcuityPlanBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanBundle) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanBundleRequiredSegmentRule: AcuityPlanBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanBundle) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanBundleCodePrefixRule: AcuityPlanBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AcuityPlanBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AcuityPlanBundleRequiredCodeRule: AcuityPlanBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanBundleAllowedTitleRule: AcuityPlanBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AcuityPlanBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class AcuityPlanBundleCodeLengthRule: AcuityPlanBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan bundle.
    final class AcuityPlanBundleValidator {
        var rules: [any AcuityPlanBundleRule]

        init(rules: [any AcuityPlanBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanBundle) -> [String] {
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

        func requireValid(_ item: AcuityPlanBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanBundle]) -> [String: [String]] {
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

    static func defaultAcuityPlanBundleValidator() -> AcuityPlanBundleValidator {
        return AcuityPlanBundleValidator(
            rules: [
                AcuityPlanBundleAcuityRangeRule(min: 3600, max: 86400),
                AcuityPlanBundleRequiredSegmentRule(message: "acuity plan bundle needs this field"),
                AcuityPlanBundleCodePrefixRule(prefix: "ACM"),
                AcuityPlanBundleRequiredCodeRule(message: "acuity plan bundle needs this field"),
                AcuityPlanBundleAllowedTitleRule(allowed: ["regional"]),
                AcuityPlanBundleCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
