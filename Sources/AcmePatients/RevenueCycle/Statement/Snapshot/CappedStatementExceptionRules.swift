import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped statement exception must pass. Check returns its problems, or none.
    protocol CappedStatementExceptionRule {
        func check(_ item: CappedStatementException) -> [String]
    }

    final class CappedStatementExceptionCodeLengthRule: CappedStatementExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedStatementException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedStatementExceptionRequiredNotesRule: CappedStatementExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedStatementException) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedStatementExceptionFloorValueRangeRule: CappedStatementExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedStatementException) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedStatementExceptionCodePrefixRule: CappedStatementExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedStatementException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedStatementExceptionNotesLengthRule: CappedStatementExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedStatementException) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedStatementExceptionLabelLengthRule: CappedStatementExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedStatementException) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped statement exception.
    final class CappedStatementExceptionValidator {
        var rules: [any CappedStatementExceptionRule]

        init(rules: [any CappedStatementExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedStatementException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedStatementException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedStatementException]) -> [String: [String]] {
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

    static func defaultCappedStatementExceptionValidator() -> CappedStatementExceptionValidator {
        return CappedStatementExceptionValidator(
            rules: [
                CappedStatementExceptionCodeLengthRule(maxLength: 1000),
                CappedStatementExceptionRequiredNotesRule(message: "capped statement exception needs a value"),
                CappedStatementExceptionFloorValueRangeRule(min: 1.3, max: 3536.8),
                CappedStatementExceptionCodePrefixRule(prefix: "ACM"),
                CappedStatementExceptionNotesLengthRule(maxLength: 255),
                CappedStatementExceptionLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
