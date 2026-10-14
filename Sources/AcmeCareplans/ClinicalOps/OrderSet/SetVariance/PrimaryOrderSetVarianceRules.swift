import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary order set variance must pass. Check returns its problems, or none.
    protocol PrimaryOrderSetVarianceRule {
        func check(_ item: PrimaryOrderSetVariance) -> [String]
    }

    final class PrimaryOrderSetVarianceNameLengthRule: PrimaryOrderSetVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOrderSetVariance) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOrderSetVarianceRequiredCodeRule: PrimaryOrderSetVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOrderSetVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryOrderSetVarianceRequiredChannelRule: PrimaryOrderSetVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOrderSetVariance) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary order set variance.
    final class PrimaryOrderSetVarianceValidator {
        var rules: [any PrimaryOrderSetVarianceRule]

        init(rules: [any PrimaryOrderSetVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOrderSetVariance) -> [String] {
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

        func requireValid(_ item: PrimaryOrderSetVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOrderSetVariance]) -> [String: [String]] {
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

    static func defaultPrimaryOrderSetVarianceValidator() -> PrimaryOrderSetVarianceValidator {
        return PrimaryOrderSetVarianceValidator(
            rules: [
                PrimaryOrderSetVarianceNameLengthRule(maxLength: 1000),
                PrimaryOrderSetVarianceRequiredCodeRule(message: "primary order set variance needs this field"),
                PrimaryOrderSetVarianceRequiredChannelRule(message: "primary order set variance needs this field"),
            ]
        )
    }
}
