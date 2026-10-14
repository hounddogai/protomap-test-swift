import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial segment must pass. Check returns its problems, or none.
    protocol DenialSegmentRule {
        func check(_ item: DenialSegment) -> [String]
    }

    final class DenialSegmentRequiredCodeRule: DenialSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialSegmentActiveGuardRule: DenialSegmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DenialSegment) -> [String] {
            if item.active && (item.batchSize > limit) {
                return ["batch size \(item.batchSize) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class DenialSegmentCodeLengthRule: DenialSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial segment.
    final class DenialSegmentValidator {
        var rules: [any DenialSegmentRule]

        init(rules: [any DenialSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialSegment) -> [String] {
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

        func requireValid(_ item: DenialSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialSegment]) -> [String: [String]] {
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

    static func defaultDenialSegmentValidator() -> DenialSegmentValidator {
        return DenialSegmentValidator(
            rules: [
                DenialSegmentRequiredCodeRule(message: "denial segment needs an entry"),
                DenialSegmentActiveGuardRule(limit: 16),
                DenialSegmentCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
