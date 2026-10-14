import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive rounding segment must pass. Check returns its problems, or none.
    protocol AdaptiveRoundingSegmentRule {
        func check(_ item: AdaptiveRoundingSegment) -> [String]
    }

    final class AdaptiveRoundingSegmentCodeLengthRule: AdaptiveRoundingSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRoundingSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRoundingSegmentNameLengthRule: AdaptiveRoundingSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRoundingSegment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRoundingSegmentRequiredNameRule: AdaptiveRoundingSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRoundingSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRoundingSegmentRequiredCodeRule: AdaptiveRoundingSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRoundingSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRoundingSegmentCodePrefixRule: AdaptiveRoundingSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveRoundingSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveRoundingSegmentLimitRangeRule: AdaptiveRoundingSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRoundingSegment) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive rounding segment.
    final class AdaptiveRoundingSegmentValidator {
        var rules: [any AdaptiveRoundingSegmentRule]

        init(rules: [any AdaptiveRoundingSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRoundingSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveRoundingSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRoundingSegment]) -> [String: [String]] {
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

    static func defaultAdaptiveRoundingSegmentValidator() -> AdaptiveRoundingSegmentValidator {
        return AdaptiveRoundingSegmentValidator(
            rules: [
                AdaptiveRoundingSegmentCodeLengthRule(maxLength: 64),
                AdaptiveRoundingSegmentNameLengthRule(maxLength: 86400),
                AdaptiveRoundingSegmentRequiredNameRule(message: "adaptive rounding segment needs this field"),
                AdaptiveRoundingSegmentRequiredCodeRule(message: "adaptive rounding segment needs this field"),
                AdaptiveRoundingSegmentCodePrefixRule(prefix: "ACM"),
                AdaptiveRoundingSegmentLimitRangeRule(min: 255, max: 3600),
            ]
        )
    }
}
