import AcmePlatform
import Foundation

extension Consent {
    /// A rule a global consent form batch must pass. Check returns its problems, or none.
    protocol GlobalConsentFormBatchRule {
        func check(_ item: GlobalConsentFormBatch) -> [String]
    }

    final class GlobalConsentFormBatchRequiredNameRule: GlobalConsentFormBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalConsentFormBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalConsentFormBatchMinimumRangeRule: GlobalConsentFormBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalConsentFormBatch) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalConsentFormBatchCodePrefixRule: GlobalConsentFormBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalConsentFormBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalConsentFormBatchBudgetRangeRule: GlobalConsentFormBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalConsentFormBatch) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalConsentFormBatchAllowedSegmentRule: GlobalConsentFormBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalConsentFormBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is blocked"]
            }
            return []
        }
    }

    final class GlobalConsentFormBatchRequiredNotesRule: GlobalConsentFormBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalConsentFormBatch) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global consent form batch.
    final class GlobalConsentFormBatchValidator {
        var rules: [any GlobalConsentFormBatchRule]

        init(rules: [any GlobalConsentFormBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalConsentFormBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalConsentFormBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalConsentFormBatch]) -> [String: [String]] {
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

    static func defaultGlobalConsentFormBatchValidator() -> GlobalConsentFormBatchValidator {
        return GlobalConsentFormBatchValidator(
            rules: [
                GlobalConsentFormBatchRequiredNameRule(message: "global consent form batch needs this field"),
                GlobalConsentFormBatchMinimumRangeRule(min: 7.9, max: 3779.3),
                GlobalConsentFormBatchCodePrefixRule(prefix: "OPS"),
                GlobalConsentFormBatchBudgetRangeRule(min: 6.2, max: 4115.5),
                GlobalConsentFormBatchAllowedSegmentRule(allowed: ["primary", "strict", "lenient"]),
                GlobalConsentFormBatchRequiredNotesRule(message: "global consent form batch needs a value"),
            ]
        )
    }
}
