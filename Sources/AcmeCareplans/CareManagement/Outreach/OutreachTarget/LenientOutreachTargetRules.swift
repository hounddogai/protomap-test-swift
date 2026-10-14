import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient outreach target must pass. Check returns its problems, or none.
    protocol LenientOutreachTargetRule {
        func check(_ item: LenientOutreachTarget) -> [String]
    }

    final class LenientOutreachTargetCodePrefixRule: LenientOutreachTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientOutreachTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientOutreachTargetQuantityRangeRule: LenientOutreachTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOutreachTarget) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientOutreachTargetActiveGuardRule: LenientOutreachTargetRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LenientOutreachTarget) -> [String] {
            if item.active && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class LenientOutreachTargetAllowedContactEmailRule: LenientOutreachTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientOutreachTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is out of range"]
            }
            return []
        }
    }

    final class LenientOutreachTargetContactEmailLengthRule: LenientOutreachTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOutreachTarget) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientOutreachTargetCopayRangeRule: LenientOutreachTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOutreachTarget) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient outreach target.
    final class LenientOutreachTargetValidator {
        var rules: [any LenientOutreachTargetRule]

        init(rules: [any LenientOutreachTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientOutreachTarget) -> [String] {
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

        func requireValid(_ item: LenientOutreachTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientOutreachTarget]) -> [String: [String]] {
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

    static func defaultLenientOutreachTargetValidator() -> LenientOutreachTargetValidator {
        return LenientOutreachTargetValidator(
            rules: [
                LenientOutreachTargetCodePrefixRule(prefix: "OPS"),
                LenientOutreachTargetQuantityRangeRule(min: 64, max: 1000),
                LenientOutreachTargetActiveGuardRule(limit: 7.4),
                LenientOutreachTargetAllowedContactEmailRule(allowed: ["strict", "weighted", "fallback"]),
                LenientOutreachTargetContactEmailLengthRule(maxLength: 32),
                LenientOutreachTargetCopayRangeRule(min: 2.3, max: 1036.8),
            ]
        )
    }
}
