import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality rollup must pass. Check returns its problems, or none.
    protocol ModalityRollupRule {
        func check(_ item: ModalityRollup) -> [String]
    }

    final class ModalityRollupAllowedWardRule: ModalityRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ModalityRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is above maximum"]
            }
            return []
        }
    }

    final class ModalityRollupVersionRangeRule: ModalityRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityRollup) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityRollupRequiredReviewerRule: ModalityRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityRollup) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityRollupRequiredBedRule: ModalityRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityRollup) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a modality rollup.
    final class ModalityRollupValidator {
        var rules: [any ModalityRollupRule]

        init(rules: [any ModalityRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityRollup]) -> [String: [String]] {
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

    static func defaultModalityRollupValidator() -> ModalityRollupValidator {
        return ModalityRollupValidator(
            rules: [
                ModalityRollupAllowedWardRule(allowed: ["fallback", "capped", "rolling"]),
                ModalityRollupVersionRangeRule(min: 32, max: 86400),
                ModalityRollupRequiredReviewerRule(message: "modality rollup needs an entry"),
                ModalityRollupRequiredBedRule(message: "modality rollup needs a value"),
            ]
        )
    }
}
