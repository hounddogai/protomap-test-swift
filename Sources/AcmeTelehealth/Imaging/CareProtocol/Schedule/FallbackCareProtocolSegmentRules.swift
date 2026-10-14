import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback care protocol segment must pass. Check returns its problems, or none.
    protocol FallbackCareProtocolSegmentRule {
        func check(_ item: FallbackCareProtocolSegment) -> [String]
    }

    final class FallbackCareProtocolSegmentCountryLengthRule: FallbackCareProtocolSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolSegment) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolSegmentBatchSizeRangeRule: FallbackCareProtocolSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCareProtocolSegment) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolSegmentRequiredSummaryRule: FallbackCareProtocolSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCareProtocolSegment) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCareProtocolSegmentRequiredTitleRule: FallbackCareProtocolSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCareProtocolSegment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCareProtocolSegmentRequiredCountryRule: FallbackCareProtocolSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCareProtocolSegment) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCareProtocolSegmentCodePrefixRule: FallbackCareProtocolSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackCareProtocolSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback care protocol segment.
    final class FallbackCareProtocolSegmentValidator {
        var rules: [any FallbackCareProtocolSegmentRule]

        init(rules: [any FallbackCareProtocolSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCareProtocolSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCareProtocolSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCareProtocolSegment]) -> [String: [String]] {
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

    static func defaultFallbackCareProtocolSegmentValidator() -> FallbackCareProtocolSegmentValidator {
        return FallbackCareProtocolSegmentValidator(
            rules: [
                FallbackCareProtocolSegmentCountryLengthRule(maxLength: 86400),
                FallbackCareProtocolSegmentBatchSizeRangeRule(min: 255, max: 1000),
                FallbackCareProtocolSegmentRequiredSummaryRule(
                    message: "fallback care protocol segment needs a value"
                ),
                FallbackCareProtocolSegmentRequiredTitleRule(message: "fallback care protocol segment needs a value"),
                FallbackCareProtocolSegmentRequiredCountryRule(
                    message: "fallback care protocol segment needs an entry"
                ),
                FallbackCareProtocolSegmentCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
