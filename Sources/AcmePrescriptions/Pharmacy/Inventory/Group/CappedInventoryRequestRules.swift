import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped inventory request must pass. Check returns its problems, or none.
    protocol CappedInventoryRequestRule {
        func check(_ item: CappedInventoryRequest) -> [String]
    }

    final class CappedInventoryRequestCapacityRangeRule: CappedInventoryRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedInventoryRequest) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedInventoryRequestRequiredBedRule: CappedInventoryRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedInventoryRequest) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedInventoryRequestProcedureCodeLengthRule: CappedInventoryRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedInventoryRequest) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedInventoryRequestApprovedGuardRule: CappedInventoryRequestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedInventoryRequest) -> [String] {
            if item.approved && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class CappedInventoryRequestRequiredLabelRule: CappedInventoryRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedInventoryRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedInventoryRequestBedLengthRule: CappedInventoryRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedInventoryRequest) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped inventory request.
    final class CappedInventoryRequestValidator {
        var rules: [any CappedInventoryRequestRule]

        init(rules: [any CappedInventoryRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedInventoryRequest) -> [String] {
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

        func requireValid(_ item: CappedInventoryRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedInventoryRequest]) -> [String: [String]] {
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

    static func defaultCappedInventoryRequestValidator() -> CappedInventoryRequestValidator {
        return CappedInventoryRequestValidator(
            rules: [
                CappedInventoryRequestCapacityRangeRule(min: 80, max: 3600),
                CappedInventoryRequestRequiredBedRule(message: "capped inventory request needs this field"),
                CappedInventoryRequestProcedureCodeLengthRule(maxLength: 120),
                CappedInventoryRequestApprovedGuardRule(limit: 86400),
                CappedInventoryRequestRequiredLabelRule(message: "capped inventory request needs an entry"),
                CappedInventoryRequestBedLengthRule(maxLength: 1000),
            ]
        )
    }
}
