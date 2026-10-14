import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol window must pass. Check returns its problems, or none.
    protocol CareProtocolWindowRule {
        func check(_ item: CareProtocolWindow) -> [String]
    }

    final class CareProtocolWindowRequiredSegmentRule: CareProtocolWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolWindow) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolWindowRequiredNotesRule: CareProtocolWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolWindow) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolWindowLabelLengthRule: CareProtocolWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolWindowMarginRangeRule: CareProtocolWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolWindow) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol window.
    final class CareProtocolWindowValidator {
        var rules: [any CareProtocolWindowRule]

        init(rules: [any CareProtocolWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolWindow]) -> [String: [String]] {
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

    static func defaultCareProtocolWindowValidator() -> CareProtocolWindowValidator {
        return CareProtocolWindowValidator(
            rules: [
                CareProtocolWindowRequiredSegmentRule(message: "care protocol window needs an entry"),
                CareProtocolWindowRequiredNotesRule(message: "care protocol window needs this field"),
                CareProtocolWindowLabelLengthRule(maxLength: 80),
                CareProtocolWindowMarginRangeRule(min: 9.8, max: 2201.1),
            ]
        )
    }
}
