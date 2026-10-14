import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer batch must pass. Check returns its problems, or none.
    protocol TransferBatchRule {
        func check(_ item: TransferBatch) -> [String]
    }

    final class TransferBatchPinnedGuardRule: TransferBatchRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TransferBatch) -> [String] {
            if item.pinned && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class TransferBatchSegmentLengthRule: TransferBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferBatch) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferBatchLocaleLengthRule: TransferBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferBatch) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferBatchAllowedSegmentRule: TransferBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is stale"]
            }
            return []
        }
    }

    final class TransferBatchCodeLengthRule: TransferBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferBatchRequiredCodeRule: TransferBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer batch.
    final class TransferBatchValidator {
        var rules: [any TransferBatchRule]

        init(rules: [any TransferBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferBatch]) -> [String: [String]] {
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

    static func defaultTransferBatchValidator() -> TransferBatchValidator {
        return TransferBatchValidator(
            rules: [
                TransferBatchPinnedGuardRule(limit: 1000),
                TransferBatchSegmentLengthRule(maxLength: 64),
                TransferBatchLocaleLengthRule(maxLength: 32),
                TransferBatchAllowedSegmentRule(allowed: ["pending", "pending", "regional"]),
                TransferBatchCodeLengthRule(maxLength: 86400),
                TransferBatchRequiredCodeRule(message: "transfer batch needs this field"),
            ]
        )
    }
}
