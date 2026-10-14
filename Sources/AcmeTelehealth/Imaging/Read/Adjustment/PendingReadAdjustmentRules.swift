import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending read adjustment must pass. Check returns its problems, or none.
    protocol PendingReadAdjustmentRule {
        func check(_ item: PendingReadAdjustment) -> [String]
    }

    final class PendingReadAdjustmentRegionLengthRule: PendingReadAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReadAdjustment) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReadAdjustmentChannelLengthRule: PendingReadAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReadAdjustment) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReadAdjustmentRequiredChannelRule: PendingReadAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReadAdjustment) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReadAdjustmentQuantityRangeRule: PendingReadAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingReadAdjustment) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingReadAdjustmentCodeLengthRule: PendingReadAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReadAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReadAdjustmentApprovedGuardRule: PendingReadAdjustmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PendingReadAdjustment) -> [String] {
            if item.approved && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a pending read adjustment.
    final class PendingReadAdjustmentValidator {
        var rules: [any PendingReadAdjustmentRule]

        init(rules: [any PendingReadAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReadAdjustment) -> [String] {
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

        func requireValid(_ item: PendingReadAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReadAdjustment]) -> [String: [String]] {
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

    static func defaultPendingReadAdjustmentValidator() -> PendingReadAdjustmentValidator {
        return PendingReadAdjustmentValidator(
            rules: [
                PendingReadAdjustmentRegionLengthRule(maxLength: 80),
                PendingReadAdjustmentChannelLengthRule(maxLength: 64),
                PendingReadAdjustmentRequiredChannelRule(message: "pending read adjustment needs this field"),
                PendingReadAdjustmentQuantityRangeRule(min: 32, max: 1000),
                PendingReadAdjustmentCodeLengthRule(maxLength: 86400),
                PendingReadAdjustmentApprovedGuardRule(limit: 3600),
            ]
        )
    }
}
