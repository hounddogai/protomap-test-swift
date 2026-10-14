import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality policy must pass. Check returns its problems, or none.
    protocol ModalityPolicyRule {
        func check(_ item: ModalityPolicy) -> [String]
    }

    final class ModalityPolicyReviewerLengthRule: ModalityPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityPolicy) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityPolicySpecialtyLengthRule: ModalityPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityPolicy) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityPolicyUpdatedAtRangeRule: ModalityPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityPolicy) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ModalityPolicyNameLengthRule: ModalityPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityPolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityPolicyAllowedSpecialtyRule: ModalityPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ModalityPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is expired"]
            }
            return []
        }
    }

    final class ModalityPolicyRatioRangeRule: ModalityPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityPolicy) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality policy.
    final class ModalityPolicyValidator {
        var rules: [any ModalityPolicyRule]

        init(rules: [any ModalityPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityPolicy) -> [String] {
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

        func requireValid(_ item: ModalityPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityPolicy]) -> [String: [String]] {
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

    static func defaultModalityPolicyValidator() -> ModalityPolicyValidator {
        return ModalityPolicyValidator(
            rules: [
                ModalityPolicyReviewerLengthRule(maxLength: 3600),
                ModalityPolicySpecialtyLengthRule(maxLength: 1000),
                ModalityPolicyUpdatedAtRangeRule(min: 32, max: 80),
                ModalityPolicyNameLengthRule(maxLength: 86400),
                ModalityPolicyAllowedSpecialtyRule(allowed: ["regional"]),
                ModalityPolicyRatioRangeRule(min: 6.5, max: 2227.5),
            ]
        )
    }
}
