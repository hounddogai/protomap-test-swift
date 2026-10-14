import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual bed board window must pass. Check returns its problems, or none.
    protocol ManualBedBoardWindowRule {
        func check(_ item: ManualBedBoardWindow) -> [String]
    }

    final class ManualBedBoardWindowRequiredCodeRule: ManualBedBoardWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualBedBoardWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualBedBoardWindowActiveGuardRule: ManualBedBoardWindowRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ManualBedBoardWindow) -> [String] {
            if item.active && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ManualBedBoardWindowCodePrefixRule: ManualBedBoardWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualBedBoardWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualBedBoardWindowCodeLengthRule: ManualBedBoardWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualBedBoardWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual bed board window.
    final class ManualBedBoardWindowValidator {
        var rules: [any ManualBedBoardWindowRule]

        init(rules: [any ManualBedBoardWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualBedBoardWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualBedBoardWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualBedBoardWindow]) -> [String: [String]] {
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

    static func defaultManualBedBoardWindowValidator() -> ManualBedBoardWindowValidator {
        return ManualBedBoardWindowValidator(
            rules: [
                ManualBedBoardWindowRequiredCodeRule(message: "manual bed board window needs a value"),
                ManualBedBoardWindowActiveGuardRule(limit: 32),
                ManualBedBoardWindowCodePrefixRule(prefix: "Q"),
                ManualBedBoardWindowCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
