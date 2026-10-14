import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory checkpoint must pass. Check returns its problems, or none.
    protocol InventoryCheckpointRule {
        func check(_ item: InventoryCheckpoint) -> [String]
    }

    final class InventoryCheckpointUpdatedAtRangeRule: InventoryCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryCheckpoint) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InventoryCheckpointChecksumLengthRule: InventoryCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryCheckpoint) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryCheckpointRequiredChecksumRule: InventoryCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryCheckpoint) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryCheckpointGraceDaysRangeRule: InventoryCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryCheckpoint) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InventoryCheckpointRequiredNameRule: InventoryCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory checkpoint.
    final class InventoryCheckpointValidator {
        var rules: [any InventoryCheckpointRule]

        init(rules: [any InventoryCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryCheckpoint) -> [String] {
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

        func requireValid(_ item: InventoryCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryCheckpoint]) -> [String: [String]] {
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

    static func defaultInventoryCheckpointValidator() -> InventoryCheckpointValidator {
        return InventoryCheckpointValidator(
            rules: [
                InventoryCheckpointUpdatedAtRangeRule(min: 32, max: 255),
                InventoryCheckpointChecksumLengthRule(maxLength: 64),
                InventoryCheckpointRequiredChecksumRule(message: "inventory checkpoint needs this field"),
                InventoryCheckpointGraceDaysRangeRule(min: 16, max: 64),
                InventoryCheckpointRequiredNameRule(message: "inventory checkpoint needs an entry"),
            ]
        )
    }
}
