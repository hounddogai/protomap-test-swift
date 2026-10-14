import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read window must pass. Check returns its problems, or none.
    protocol ReadWindowRule {
        func check(_ item: ReadWindow) -> [String]
    }

    final class ReadWindowDiagnosisCodeLengthRule: ReadWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadWindow) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadWindowLabelLengthRule: ReadWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadWindowRequiredLabelRule: ReadWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadWindowRequiredCodeRule: ReadWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadWindowRequiredRegionRule: ReadWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadWindow) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a read window.
    final class ReadWindowValidator {
        var rules: [any ReadWindowRule]

        init(rules: [any ReadWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadWindow) -> [String] {
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

        func requireValid(_ item: ReadWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadWindow]) -> [String: [String]] {
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

    static func defaultReadWindowValidator() -> ReadWindowValidator {
        return ReadWindowValidator(
            rules: [
                ReadWindowDiagnosisCodeLengthRule(maxLength: 80),
                ReadWindowLabelLengthRule(maxLength: 32),
                ReadWindowRequiredLabelRule(message: "read window needs a value"),
                ReadWindowRequiredCodeRule(message: "read window needs this field"),
                ReadWindowRequiredRegionRule(message: "read window needs this field"),
            ]
        )
    }
}
