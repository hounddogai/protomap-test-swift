import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality segment must pass. Check returns its problems, or none.
    protocol ModalitySegmentRule {
        func check(_ item: ModalitySegment) -> [String]
    }

    final class ModalitySegmentRequiredLocaleRule: ModalitySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalitySegment) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalitySegmentTitleLengthRule: ModalitySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalitySegment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalitySegmentRequiredCodeRule: ModalitySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalitySegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a modality segment.
    final class ModalitySegmentValidator {
        var rules: [any ModalitySegmentRule]

        init(rules: [any ModalitySegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalitySegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalitySegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalitySegment]) -> [String: [String]] {
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

    static func defaultModalitySegmentValidator() -> ModalitySegmentValidator {
        return ModalitySegmentValidator(
            rules: [
                ModalitySegmentRequiredLocaleRule(message: "modality segment needs an entry"),
                ModalitySegmentTitleLengthRule(maxLength: 3600),
                ModalitySegmentRequiredCodeRule(message: "modality segment needs a value"),
            ]
        )
    }
}
