import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending formulary review must pass. Check returns its problems, or none.
    protocol PendingFormularyReviewRule {
        func check(_ item: PendingFormularyReview) -> [String]
    }

    final class PendingFormularyReviewVisibleGuardRule: PendingFormularyReviewRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PendingFormularyReview) -> [String] {
            if item.visible && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class PendingFormularyReviewOwnerIDLengthRule: PendingFormularyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFormularyReview) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingFormularyReviewAllowedOwnerIDRule: PendingFormularyReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingFormularyReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is above maximum"]
            }
            return []
        }
    }

    final class PendingFormularyReviewRequiredOwnerIDRule: PendingFormularyReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingFormularyReview) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingFormularyReviewDiscountRangeRule: PendingFormularyReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingFormularyReview) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingFormularyReviewNameLengthRule: PendingFormularyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFormularyReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending formulary review.
    final class PendingFormularyReviewValidator {
        var rules: [any PendingFormularyReviewRule]

        init(rules: [any PendingFormularyReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingFormularyReview) -> [String] {
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

        func requireValid(_ item: PendingFormularyReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingFormularyReview]) -> [String: [String]] {
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

    static func defaultPendingFormularyReviewValidator() -> PendingFormularyReviewValidator {
        return PendingFormularyReviewValidator(
            rules: [
                PendingFormularyReviewVisibleGuardRule(limit: 2.6),
                PendingFormularyReviewOwnerIDLengthRule(maxLength: 1000),
                PendingFormularyReviewAllowedOwnerIDRule(allowed: ["manual", "regional"]),
                PendingFormularyReviewRequiredOwnerIDRule(message: "pending formulary review needs an entry"),
                PendingFormularyReviewDiscountRangeRule(min: 1.9, max: 4342.6),
                PendingFormularyReviewNameLengthRule(maxLength: 64),
            ]
        )
    }
}
