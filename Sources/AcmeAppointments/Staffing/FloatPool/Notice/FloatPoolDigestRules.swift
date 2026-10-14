import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool digest must pass. Check returns its problems, or none.
    protocol FloatPoolDigestRule {
        func check(_ item: FloatPoolDigest) -> [String]
    }

    final class FloatPoolDigestAmountRangeRule: FloatPoolDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolDigest) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FloatPoolDigestDescriptionLengthRule: FloatPoolDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolDigest) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolDigestCodeLengthRule: FloatPoolDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolDigestRequiredCodeRule: FloatPoolDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a float pool digest.
    final class FloatPoolDigestValidator {
        var rules: [any FloatPoolDigestRule]

        init(rules: [any FloatPoolDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolDigest) -> [String] {
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

        func requireValid(_ item: FloatPoolDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolDigest]) -> [String: [String]] {
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

    static func defaultFloatPoolDigestValidator() -> FloatPoolDigestValidator {
        return FloatPoolDigestValidator(
            rules: [
                FloatPoolDigestAmountRangeRule(min: 4.3, max: 3588.7),
                FloatPoolDigestDescriptionLengthRule(maxLength: 32),
                FloatPoolDigestCodeLengthRule(maxLength: 86400),
                FloatPoolDigestRequiredCodeRule(message: "float pool digest needs a value"),
            ]
        )
    }
}
