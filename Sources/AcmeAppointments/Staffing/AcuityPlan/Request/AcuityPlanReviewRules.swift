import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan review must pass. Check returns its problems, or none.
    protocol AcuityPlanReviewRule {
        func check(_ item: AcuityPlanReview) -> [String]
    }

    final class AcuityPlanReviewCodeLengthRule: AcuityPlanReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanReviewAllowedCodeRule: AcuityPlanReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AcuityPlanReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class AcuityPlanReviewRequiredCodeRule: AcuityPlanReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanReviewRequiredTimezoneRule: AcuityPlanReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanReview) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanReviewCodePrefixRule: AcuityPlanReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AcuityPlanReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AcuityPlanReviewNameLengthRule: AcuityPlanReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan review.
    final class AcuityPlanReviewValidator {
        var rules: [any AcuityPlanReviewRule]

        init(rules: [any AcuityPlanReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanReview) -> [String] {
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

        func requireValid(_ item: AcuityPlanReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanReview]) -> [String: [String]] {
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

    static func defaultAcuityPlanReviewValidator() -> AcuityPlanReviewValidator {
        return AcuityPlanReviewValidator(
            rules: [
                AcuityPlanReviewCodeLengthRule(maxLength: 3600),
                AcuityPlanReviewAllowedCodeRule(allowed: ["fallback", "weighted"]),
                AcuityPlanReviewRequiredCodeRule(message: "acuity plan review needs a value"),
                AcuityPlanReviewRequiredTimezoneRule(message: "acuity plan review needs a value"),
                AcuityPlanReviewCodePrefixRule(prefix: "REF"),
                AcuityPlanReviewNameLengthRule(maxLength: 32),
            ]
        )
    }
}
