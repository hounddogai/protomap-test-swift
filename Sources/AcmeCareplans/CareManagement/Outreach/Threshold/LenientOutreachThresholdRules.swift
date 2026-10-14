import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient outreach threshold must pass. Check returns its problems, or none.
    protocol LenientOutreachThresholdRule {
        func check(_ item: LenientOutreachThreshold) -> [String]
    }

    final class LenientOutreachThresholdDosageMgRangeRule: LenientOutreachThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOutreachThreshold) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientOutreachThresholdAllowedContactEmailRule: LenientOutreachThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientOutreachThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is stale"]
            }
            return []
        }
    }

    final class LenientOutreachThresholdRequiredNameRule: LenientOutreachThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOutreachThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOutreachThresholdQuantityRangeRule: LenientOutreachThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOutreachThreshold) -> [String] {
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

    /// Runs every rule of a lenient outreach threshold.
    final class LenientOutreachThresholdValidator {
        var rules: [any LenientOutreachThresholdRule]

        init(rules: [any LenientOutreachThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientOutreachThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientOutreachThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientOutreachThreshold]) -> [String: [String]] {
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

    static func defaultLenientOutreachThresholdValidator() -> LenientOutreachThresholdValidator {
        return LenientOutreachThresholdValidator(
            rules: [
                LenientOutreachThresholdDosageMgRangeRule(min: 8.0, max: 713.8),
                LenientOutreachThresholdAllowedContactEmailRule(allowed: []),
                LenientOutreachThresholdRequiredNameRule(message: "lenient outreach threshold needs an entry"),
                LenientOutreachThresholdQuantityRangeRule(min: 86400, max: 86400),
            ]
        )
    }
}
