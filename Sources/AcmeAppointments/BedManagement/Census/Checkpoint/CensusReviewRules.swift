import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census review must pass. Check returns its problems, or none.
    protocol CensusReviewRule {
        func check(_ item: CensusReview) -> [String]
    }

    final class CensusReviewCodeLengthRule: CensusReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusReviewWeightRangeRule: CensusReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusReview) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusReviewLabelLengthRule: CensusReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusReviewCodePrefixRule: CensusReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusReviewRequiredNameRule: CensusReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusReviewRequiredLabelRule: CensusReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census review.
    final class CensusReviewValidator {
        var rules: [any CensusReviewRule]

        init(rules: [any CensusReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusReview) -> [String] {
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

        func requireValid(_ item: CensusReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusReview]) -> [String: [String]] {
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

    static func defaultCensusReviewValidator() -> CensusReviewValidator {
        return CensusReviewValidator(
            rules: [
                CensusReviewCodeLengthRule(maxLength: 64),
                CensusReviewWeightRangeRule(min: 0.8, max: 2263.1),
                CensusReviewLabelLengthRule(maxLength: 3600),
                CensusReviewCodePrefixRule(prefix: "X"),
                CensusReviewRequiredNameRule(message: "census review needs a value"),
                CensusReviewRequiredLabelRule(message: "census review needs this field"),
            ]
        )
    }
}
