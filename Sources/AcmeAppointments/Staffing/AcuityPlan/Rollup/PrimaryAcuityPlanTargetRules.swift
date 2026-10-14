import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary acuity plan target must pass. Check returns its problems, or none.
    protocol PrimaryAcuityPlanTargetRule {
        func check(_ item: PrimaryAcuityPlanTarget) -> [String]
    }

    final class PrimaryAcuityPlanTargetTitleLengthRule: PrimaryAcuityPlanTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAcuityPlanTarget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanTargetRequiredSegmentRule: PrimaryAcuityPlanTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAcuityPlanTarget) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanTargetCodeLengthRule: PrimaryAcuityPlanTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAcuityPlanTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanTargetRequiredTitleRule: PrimaryAcuityPlanTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAcuityPlanTarget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanTargetCodePrefixRule: PrimaryAcuityPlanTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryAcuityPlanTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanTargetWardLengthRule: PrimaryAcuityPlanTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAcuityPlanTarget) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary acuity plan target.
    final class PrimaryAcuityPlanTargetValidator {
        var rules: [any PrimaryAcuityPlanTargetRule]

        init(rules: [any PrimaryAcuityPlanTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAcuityPlanTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryAcuityPlanTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAcuityPlanTarget]) -> [String: [String]] {
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

    static func defaultPrimaryAcuityPlanTargetValidator() -> PrimaryAcuityPlanTargetValidator {
        return PrimaryAcuityPlanTargetValidator(
            rules: [
                PrimaryAcuityPlanTargetTitleLengthRule(maxLength: 80),
                PrimaryAcuityPlanTargetRequiredSegmentRule(message: "primary acuity plan target needs this field"),
                PrimaryAcuityPlanTargetCodeLengthRule(maxLength: 3600),
                PrimaryAcuityPlanTargetRequiredTitleRule(message: "primary acuity plan target needs this field"),
                PrimaryAcuityPlanTargetCodePrefixRule(prefix: "OPS"),
                PrimaryAcuityPlanTargetWardLengthRule(maxLength: 120),
            ]
        )
    }
}
