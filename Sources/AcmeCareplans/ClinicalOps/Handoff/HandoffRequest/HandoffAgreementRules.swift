import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff agreement must pass. Check returns its problems, or none.
    protocol HandoffAgreementRule {
        func check(_ item: HandoffAgreement) -> [String]
    }

    final class HandoffAgreementBedLengthRule: HandoffAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffAgreement) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffAgreementTitleLengthRule: HandoffAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffAgreementRequiredDiagnosisCodeRule: HandoffAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffAgreement) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffAgreementDosageMgRangeRule: HandoffAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffAgreement) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class HandoffAgreementRequiredBedRule: HandoffAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffAgreement) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffAgreementVisitMinutesRangeRule: HandoffAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffAgreement) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff agreement.
    final class HandoffAgreementValidator {
        var rules: [any HandoffAgreementRule]

        init(rules: [any HandoffAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffAgreement]) -> [String: [String]] {
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

    static func defaultHandoffAgreementValidator() -> HandoffAgreementValidator {
        return HandoffAgreementValidator(
            rules: [
                HandoffAgreementBedLengthRule(maxLength: 1000),
                HandoffAgreementTitleLengthRule(maxLength: 1000),
                HandoffAgreementRequiredDiagnosisCodeRule(message: "handoff agreement needs a value"),
                HandoffAgreementDosageMgRangeRule(min: 8.3, max: 1249.3),
                HandoffAgreementRequiredBedRule(message: "handoff agreement needs a value"),
                HandoffAgreementVisitMinutesRangeRule(min: 255, max: 255),
            ]
        )
    }
}
