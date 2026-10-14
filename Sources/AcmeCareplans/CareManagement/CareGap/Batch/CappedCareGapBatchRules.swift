import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped care gap batch must pass. Check returns its problems, or none.
    protocol CappedCareGapBatchRule {
        func check(_ item: CappedCareGapBatch) -> [String]
    }

    final class CappedCareGapBatchRequiredSegmentRule: CappedCareGapBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCareGapBatch) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCareGapBatchNameLengthRule: CappedCareGapBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCareGapBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCareGapBatchOwnerIDLengthRule: CappedCareGapBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCareGapBatch) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCareGapBatchAllowedSegmentRule: CappedCareGapBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedCareGapBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a capped care gap batch.
    final class CappedCareGapBatchValidator {
        var rules: [any CappedCareGapBatchRule]

        init(rules: [any CappedCareGapBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCareGapBatch) -> [String] {
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

        func requireValid(_ item: CappedCareGapBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCareGapBatch]) -> [String: [String]] {
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

    static func defaultCappedCareGapBatchValidator() -> CappedCareGapBatchValidator {
        return CappedCareGapBatchValidator(
            rules: [
                CappedCareGapBatchRequiredSegmentRule(message: "capped care gap batch needs this field"),
                CappedCareGapBatchNameLengthRule(maxLength: 32),
                CappedCareGapBatchOwnerIDLengthRule(maxLength: 32),
                CappedCareGapBatchAllowedSegmentRule(allowed: ["adaptive", "legacy", "strict"]),
            ]
        )
    }
}
