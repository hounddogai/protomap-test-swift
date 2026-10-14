import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read variance must pass. Check returns its problems, or none.
    protocol ReadVarianceRule {
        func check(_ item: ReadVariance) -> [String]
    }

    final class ReadVarianceSegmentLengthRule: ReadVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadVariance) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadVarianceCodeLengthRule: ReadVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadVarianceAllowedSegmentRule: ReadVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReadVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a read variance.
    final class ReadVarianceValidator {
        var rules: [any ReadVarianceRule]

        init(rules: [any ReadVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadVariance) -> [String] {
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

        func requireValid(_ item: ReadVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadVariance]) -> [String: [String]] {
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

    static func defaultReadVarianceValidator() -> ReadVarianceValidator {
        return ReadVarianceValidator(
            rules: [
                ReadVarianceSegmentLengthRule(maxLength: 16),
                ReadVarianceCodeLengthRule(maxLength: 255),
                ReadVarianceAllowedSegmentRule(allowed: ["lenient"]),
            ]
        )
    }
}
