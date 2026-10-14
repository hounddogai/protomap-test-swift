import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched slot template must pass. Check returns its problems, or none.
    protocol BatchedSlotTemplateRule {
        func check(_ item: BatchedSlotTemplate) -> [String]
    }

    final class BatchedSlotTemplateRatioRangeRule: BatchedSlotTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSlotTemplate) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedSlotTemplateApprovedGuardRule: BatchedSlotTemplateRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: BatchedSlotTemplate) -> [String] {
            if item.approved && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class BatchedSlotTemplateAcuityRangeRule: BatchedSlotTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSlotTemplate) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedSlotTemplateAllowedProcedureCodeRule: BatchedSlotTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedSlotTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is above maximum"]
            }
            return []
        }
    }

    final class BatchedSlotTemplateCodePrefixRule: BatchedSlotTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedSlotTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched slot template.
    final class BatchedSlotTemplateValidator {
        var rules: [any BatchedSlotTemplateRule]

        init(rules: [any BatchedSlotTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSlotTemplate) -> [String] {
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

        func requireValid(_ item: BatchedSlotTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSlotTemplate]) -> [String: [String]] {
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

    static func defaultBatchedSlotTemplateValidator() -> BatchedSlotTemplateValidator {
        return BatchedSlotTemplateValidator(
            rules: [
                BatchedSlotTemplateRatioRangeRule(min: 3.9, max: 4923.5),
                BatchedSlotTemplateApprovedGuardRule(limit: 1.9),
                BatchedSlotTemplateAcuityRangeRule(min: 32, max: 255),
                BatchedSlotTemplateAllowedProcedureCodeRule(allowed: ["legacy", "seasonal", "manual"]),
                BatchedSlotTemplateCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
