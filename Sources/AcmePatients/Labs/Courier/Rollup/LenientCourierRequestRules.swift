import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient courier request must pass. Check returns its problems, or none.
    protocol LenientCourierRequestRule {
        func check(_ item: LenientCourierRequest) -> [String]
    }

    final class LenientCourierRequestRequiredLabelRule: LenientCourierRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCourierRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCourierRequestSequenceRangeRule: LenientCourierRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCourierRequest) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientCourierRequestRequiredSegmentRule: LenientCourierRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCourierRequest) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCourierRequestCodePrefixRule: LenientCourierRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientCourierRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientCourierRequestWeightRangeRule: LenientCourierRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCourierRequest) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientCourierRequestSegmentLengthRule: LenientCourierRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCourierRequest) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient courier request.
    final class LenientCourierRequestValidator {
        var rules: [any LenientCourierRequestRule]

        init(rules: [any LenientCourierRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCourierRequest) -> [String] {
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

        func requireValid(_ item: LenientCourierRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCourierRequest]) -> [String: [String]] {
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

    static func defaultLenientCourierRequestValidator() -> LenientCourierRequestValidator {
        return LenientCourierRequestValidator(
            rules: [
                LenientCourierRequestRequiredLabelRule(message: "lenient courier request needs an entry"),
                LenientCourierRequestSequenceRangeRule(min: 16, max: 80),
                LenientCourierRequestRequiredSegmentRule(message: "lenient courier request needs an entry"),
                LenientCourierRequestCodePrefixRule(prefix: "X"),
                LenientCourierRequestWeightRangeRule(min: 1.4, max: 4535.4),
                LenientCourierRequestSegmentLengthRule(maxLength: 120),
            ]
        )
    }
}
