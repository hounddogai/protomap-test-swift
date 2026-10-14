import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census target must pass. Check returns its problems, or none.
    protocol CensusTargetRule {
        func check(_ item: CensusTarget) -> [String]
    }

    final class CensusTargetChecksumLengthRule: CensusTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusTarget) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusTargetRequiredContactEmailRule: CensusTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusTarget) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusTargetEndsAtRangeRule: CensusTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusTarget) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusTargetLabelLengthRule: CensusTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a census target.
    final class CensusTargetValidator {
        var rules: [any CensusTargetRule]

        init(rules: [any CensusTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusTarget]) -> [String: [String]] {
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

    static func defaultCensusTargetValidator() -> CensusTargetValidator {
        return CensusTargetValidator(
            rules: [
                CensusTargetChecksumLengthRule(maxLength: 80),
                CensusTargetRequiredContactEmailRule(message: "census target needs this field"),
                CensusTargetEndsAtRangeRule(min: 64, max: 64),
                CensusTargetLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
