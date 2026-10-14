import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback courier segment must pass. Check returns its problems, or none.
    protocol FallbackCourierSegmentRule {
        func check(_ item: FallbackCourierSegment) -> [String]
    }

    final class FallbackCourierSegmentCountryLengthRule: FallbackCourierSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCourierSegment) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCourierSegmentCodePrefixRule: FallbackCourierSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackCourierSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackCourierSegmentCodeLengthRule: FallbackCourierSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCourierSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback courier segment.
    final class FallbackCourierSegmentValidator {
        var rules: [any FallbackCourierSegmentRule]

        init(rules: [any FallbackCourierSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCourierSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCourierSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCourierSegment]) -> [String: [String]] {
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

    static func defaultFallbackCourierSegmentValidator() -> FallbackCourierSegmentValidator {
        return FallbackCourierSegmentValidator(
            rules: [
                FallbackCourierSegmentCountryLengthRule(maxLength: 255),
                FallbackCourierSegmentCodePrefixRule(prefix: "REF"),
                FallbackCourierSegmentCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
