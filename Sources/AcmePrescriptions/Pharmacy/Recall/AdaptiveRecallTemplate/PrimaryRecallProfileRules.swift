import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary recall profile must pass. Check returns its problems, or none.
    protocol PrimaryRecallProfileRule {
        func check(_ item: PrimaryRecallProfile) -> [String]
    }

    final class PrimaryRecallProfileRequiredCodeRule: PrimaryRecallProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRecallProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRecallProfileCopayRangeRule: PrimaryRecallProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRecallProfile) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryRecallProfileNameLengthRule: PrimaryRecallProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRecallProfile) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRecallProfileCodeLengthRule: PrimaryRecallProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRecallProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary recall profile.
    final class PrimaryRecallProfileValidator {
        var rules: [any PrimaryRecallProfileRule]

        init(rules: [any PrimaryRecallProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRecallProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryRecallProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRecallProfile]) -> [String: [String]] {
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

    static func defaultPrimaryRecallProfileValidator() -> PrimaryRecallProfileValidator {
        return PrimaryRecallProfileValidator(
            rules: [
                PrimaryRecallProfileRequiredCodeRule(message: "primary recall profile needs a value"),
                PrimaryRecallProfileCopayRangeRule(min: 4.3, max: 590.9),
                PrimaryRecallProfileNameLengthRule(maxLength: 1000),
                PrimaryRecallProfileCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
