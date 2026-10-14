import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession window must pass. Check returns its problems, or none.
    protocol AccessionWindowRule {
        func check(_ item: AccessionWindow) -> [String]
    }

    final class AccessionWindowMinimumRangeRule: AccessionWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionWindow) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionWindowRequiredTitleRule: AccessionWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionWindowDiagnosisCodeLengthRule: AccessionWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionWindow) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionWindowCodePrefixRule: AccessionWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AccessionWindowActiveGuardRule: AccessionWindowRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AccessionWindow) -> [String] {
            if item.active && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a accession window.
    final class AccessionWindowValidator {
        var rules: [any AccessionWindowRule]

        init(rules: [any AccessionWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionWindow]) -> [String: [String]] {
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

    static func defaultAccessionWindowValidator() -> AccessionWindowValidator {
        return AccessionWindowValidator(
            rules: [
                AccessionWindowMinimumRangeRule(min: 7.7, max: 618.1),
                AccessionWindowRequiredTitleRule(message: "accession window needs a value"),
                AccessionWindowDiagnosisCodeLengthRule(maxLength: 16),
                AccessionWindowCodePrefixRule(prefix: "ACM"),
                AccessionWindowActiveGuardRule(limit: 1000),
            ]
        )
    }
}
