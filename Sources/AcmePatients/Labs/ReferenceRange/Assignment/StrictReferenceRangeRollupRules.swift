import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict reference range rollup must pass. Check returns its problems, or none.
    protocol StrictReferenceRangeRollupRule {
        func check(_ item: StrictReferenceRangeRollup) -> [String]
    }

    final class StrictReferenceRangeRollupUnitLengthRule: StrictReferenceRangeRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReferenceRangeRollup) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictReferenceRangeRollupRequiredPhoneRule: StrictReferenceRangeRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReferenceRangeRollup) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictReferenceRangeRollupRequiredCodeRule: StrictReferenceRangeRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReferenceRangeRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictReferenceRangeRollupPhoneLengthRule: StrictReferenceRangeRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReferenceRangeRollup) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictReferenceRangeRollupArchivedGuardRule: StrictReferenceRangeRollupRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictReferenceRangeRollup) -> [String] {
            if item.archived && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class StrictReferenceRangeRollupNameLengthRule: StrictReferenceRangeRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReferenceRangeRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict reference range rollup.
    final class StrictReferenceRangeRollupValidator {
        var rules: [any StrictReferenceRangeRollupRule]

        init(rules: [any StrictReferenceRangeRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictReferenceRangeRollup) -> [String] {
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

        func requireValid(_ item: StrictReferenceRangeRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictReferenceRangeRollup]) -> [String: [String]] {
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

    static func defaultStrictReferenceRangeRollupValidator() -> StrictReferenceRangeRollupValidator {
        return StrictReferenceRangeRollupValidator(
            rules: [
                StrictReferenceRangeRollupUnitLengthRule(maxLength: 255),
                StrictReferenceRangeRollupRequiredPhoneRule(message: "strict reference range rollup needs a value"),
                StrictReferenceRangeRollupRequiredCodeRule(message: "strict reference range rollup needs an entry"),
                StrictReferenceRangeRollupPhoneLengthRule(maxLength: 255),
                StrictReferenceRangeRollupArchivedGuardRule(limit: 1000),
                StrictReferenceRangeRollupNameLengthRule(maxLength: 120),
            ]
        )
    }
}
