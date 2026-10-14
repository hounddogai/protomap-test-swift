import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive risk score item must pass. Check returns its problems, or none.
    protocol AdaptiveRiskScoreItemRule {
        func check(_ item: AdaptiveRiskScoreItem) -> [String]
    }

    final class AdaptiveRiskScoreItemRequiredCodeRule: AdaptiveRiskScoreItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRiskScoreItem) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreItemReviewerLengthRule: AdaptiveRiskScoreItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRiskScoreItem) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreItemCodeLengthRule: AdaptiveRiskScoreItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRiskScoreItem) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreItemNameLengthRule: AdaptiveRiskScoreItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRiskScoreItem) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreItemMinimumRangeRule: AdaptiveRiskScoreItemRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRiskScoreItem) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreItemRequiredDiagnosisCodeRule: AdaptiveRiskScoreItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRiskScoreItem) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive risk score item.
    final class AdaptiveRiskScoreItemValidator {
        var rules: [any AdaptiveRiskScoreItemRule]

        init(rules: [any AdaptiveRiskScoreItemRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRiskScoreItem) -> [String] {
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

        func requireValid(_ item: AdaptiveRiskScoreItem) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRiskScoreItem]) -> [String: [String]] {
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

    static func defaultAdaptiveRiskScoreItemValidator() -> AdaptiveRiskScoreItemValidator {
        return AdaptiveRiskScoreItemValidator(
            rules: [
                AdaptiveRiskScoreItemRequiredCodeRule(message: "adaptive risk score item needs this field"),
                AdaptiveRiskScoreItemReviewerLengthRule(maxLength: 120),
                AdaptiveRiskScoreItemCodeLengthRule(maxLength: 32),
                AdaptiveRiskScoreItemNameLengthRule(maxLength: 16),
                AdaptiveRiskScoreItemMinimumRangeRule(min: 8.8, max: 4987.1),
                AdaptiveRiskScoreItemRequiredDiagnosisCodeRule(message: "adaptive risk score item needs an entry"),
            ]
        )
    }
}
