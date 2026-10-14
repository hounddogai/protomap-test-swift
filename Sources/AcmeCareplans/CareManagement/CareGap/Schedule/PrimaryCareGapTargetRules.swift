import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary care gap target must pass. Check returns its problems, or none.
    protocol PrimaryCareGapTargetRule {
        func check(_ item: PrimaryCareGapTarget) -> [String]
    }

    final class PrimaryCareGapTargetCreatedAtRangeRule: PrimaryCareGapTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCareGapTarget) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryCareGapTargetRequiredNameRule: PrimaryCareGapTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCareGapTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCareGapTargetNameLengthRule: PrimaryCareGapTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCareGapTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCareGapTargetRequiredDiagnosisCodeRule: PrimaryCareGapTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCareGapTarget) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCareGapTargetDiagnosisCodeLengthRule: PrimaryCareGapTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCareGapTarget) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary care gap target.
    final class PrimaryCareGapTargetValidator {
        var rules: [any PrimaryCareGapTargetRule]

        init(rules: [any PrimaryCareGapTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCareGapTarget) -> [String] {
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

        func requireValid(_ item: PrimaryCareGapTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCareGapTarget]) -> [String: [String]] {
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

    static func defaultPrimaryCareGapTargetValidator() -> PrimaryCareGapTargetValidator {
        return PrimaryCareGapTargetValidator(
            rules: [
                PrimaryCareGapTargetCreatedAtRangeRule(min: 80, max: 80),
                PrimaryCareGapTargetRequiredNameRule(message: "primary care gap target needs a value"),
                PrimaryCareGapTargetNameLengthRule(maxLength: 120),
                PrimaryCareGapTargetRequiredDiagnosisCodeRule(message: "primary care gap target needs an entry"),
                PrimaryCareGapTargetDiagnosisCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
