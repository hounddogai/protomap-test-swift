import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient risk score target must pass. Check returns its problems, or none.
    protocol LenientRiskScoreTargetRule {
        func check(_ item: LenientRiskScoreTarget) -> [String]
    }

    final class LenientRiskScoreTargetLabelLengthRule: LenientRiskScoreTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRiskScoreTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRiskScoreTargetRequiredCodeRule: LenientRiskScoreTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRiskScoreTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientRiskScoreTargetSegmentLengthRule: LenientRiskScoreTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRiskScoreTarget) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRiskScoreTargetRequiredLabelRule: LenientRiskScoreTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRiskScoreTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient risk score target.
    final class LenientRiskScoreTargetValidator {
        var rules: [any LenientRiskScoreTargetRule]

        init(rules: [any LenientRiskScoreTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRiskScoreTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientRiskScoreTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRiskScoreTarget]) -> [String: [String]] {
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

    static func defaultLenientRiskScoreTargetValidator() -> LenientRiskScoreTargetValidator {
        return LenientRiskScoreTargetValidator(
            rules: [
                LenientRiskScoreTargetLabelLengthRule(maxLength: 64),
                LenientRiskScoreTargetRequiredCodeRule(message: "lenient risk score target needs an entry"),
                LenientRiskScoreTargetSegmentLengthRule(maxLength: 3600),
                LenientRiskScoreTargetRequiredLabelRule(message: "lenient risk score target needs this field"),
            ]
        )
    }
}
