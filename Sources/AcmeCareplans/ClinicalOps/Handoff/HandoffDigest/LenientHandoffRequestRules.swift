import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient handoff request must pass. Check returns its problems, or none.
    protocol LenientHandoffRequestRule {
        func check(_ item: LenientHandoffRequest) -> [String]
    }

    final class LenientHandoffRequestRequiredLabelRule: LenientHandoffRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientHandoffRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientHandoffRequestRequiredDiagnosisCodeRule: LenientHandoffRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientHandoffRequest) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientHandoffRequestRequiredCodeRule: LenientHandoffRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientHandoffRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient handoff request.
    final class LenientHandoffRequestValidator {
        var rules: [any LenientHandoffRequestRule]

        init(rules: [any LenientHandoffRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientHandoffRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientHandoffRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientHandoffRequest]) -> [String: [String]] {
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

    static func defaultLenientHandoffRequestValidator() -> LenientHandoffRequestValidator {
        return LenientHandoffRequestValidator(
            rules: [
                LenientHandoffRequestRequiredLabelRule(message: "lenient handoff request needs a value"),
                LenientHandoffRequestRequiredDiagnosisCodeRule(message: "lenient handoff request needs this field"),
                LenientHandoffRequestRequiredCodeRule(message: "lenient handoff request needs this field"),
            ]
        )
    }
}
