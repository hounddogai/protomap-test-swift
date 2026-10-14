import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding mapping must pass. Check returns its problems, or none.
    protocol RoundingMappingRule {
        func check(_ item: RoundingMapping) -> [String]
    }

    final class RoundingMappingVisitMinutesRangeRule: RoundingMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingMapping) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingMappingCodePrefixRule: RoundingMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RoundingMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RoundingMappingRequiredDiagnosisCodeRule: RoundingMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingMapping) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingMappingDiagnosisCodeLengthRule: RoundingMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingMapping) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding mapping.
    final class RoundingMappingValidator {
        var rules: [any RoundingMappingRule]

        init(rules: [any RoundingMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingMapping) -> [String] {
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

        func requireValid(_ item: RoundingMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingMapping]) -> [String: [String]] {
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

    static func defaultRoundingMappingValidator() -> RoundingMappingValidator {
        return RoundingMappingValidator(
            rules: [
                RoundingMappingVisitMinutesRangeRule(min: 64, max: 3600),
                RoundingMappingCodePrefixRule(prefix: "REF"),
                RoundingMappingRequiredDiagnosisCodeRule(message: "rounding mapping needs an entry"),
                RoundingMappingDiagnosisCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
