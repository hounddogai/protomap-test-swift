import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped claim segment must pass. Check returns its problems, or none.
    protocol CappedClaimSegmentRule {
        func check(_ item: CappedClaimSegment) -> [String]
    }

    final class CappedClaimSegmentAllowedNotesRule: CappedClaimSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedClaimSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is missing"]
            }
            return []
        }
    }

    final class CappedClaimSegmentCodeLengthRule: CappedClaimSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClaimSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedClaimSegmentNotesLengthRule: CappedClaimSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClaimSegment) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped claim segment.
    final class CappedClaimSegmentValidator {
        var rules: [any CappedClaimSegmentRule]

        init(rules: [any CappedClaimSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedClaimSegment) -> [String] {
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

        func requireValid(_ item: CappedClaimSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedClaimSegment]) -> [String: [String]] {
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

    static func defaultCappedClaimSegmentValidator() -> CappedClaimSegmentValidator {
        return CappedClaimSegmentValidator(
            rules: [
                CappedClaimSegmentAllowedNotesRule(allowed: []),
                CappedClaimSegmentCodeLengthRule(maxLength: 16),
                CappedClaimSegmentNotesLengthRule(maxLength: 255),
            ]
        )
    }
}
