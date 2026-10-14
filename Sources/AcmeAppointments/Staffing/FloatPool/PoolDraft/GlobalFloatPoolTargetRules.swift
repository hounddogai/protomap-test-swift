import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global float pool target must pass. Check returns its problems, or none.
    protocol GlobalFloatPoolTargetRule {
        func check(_ item: GlobalFloatPoolTarget) -> [String]
    }

    final class GlobalFloatPoolTargetGraceDaysRangeRule: GlobalFloatPoolTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalFloatPoolTarget) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalFloatPoolTargetNameLengthRule: GlobalFloatPoolTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalFloatPoolTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalFloatPoolTargetRequiredBedRule: GlobalFloatPoolTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalFloatPoolTarget) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalFloatPoolTargetDiagnosisCodeLengthRule: GlobalFloatPoolTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalFloatPoolTarget) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalFloatPoolTargetCodeLengthRule: GlobalFloatPoolTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalFloatPoolTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalFloatPoolTargetBedLengthRule: GlobalFloatPoolTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalFloatPoolTarget) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global float pool target.
    final class GlobalFloatPoolTargetValidator {
        var rules: [any GlobalFloatPoolTargetRule]

        init(rules: [any GlobalFloatPoolTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalFloatPoolTarget) -> [String] {
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

        func requireValid(_ item: GlobalFloatPoolTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalFloatPoolTarget]) -> [String: [String]] {
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

    static func defaultGlobalFloatPoolTargetValidator() -> GlobalFloatPoolTargetValidator {
        return GlobalFloatPoolTargetValidator(
            rules: [
                GlobalFloatPoolTargetGraceDaysRangeRule(min: 32, max: 32),
                GlobalFloatPoolTargetNameLengthRule(maxLength: 86400),
                GlobalFloatPoolTargetRequiredBedRule(message: "global float pool target needs an entry"),
                GlobalFloatPoolTargetDiagnosisCodeLengthRule(maxLength: 16),
                GlobalFloatPoolTargetCodeLengthRule(maxLength: 80),
                GlobalFloatPoolTargetBedLengthRule(maxLength: 80),
            ]
        )
    }
}
