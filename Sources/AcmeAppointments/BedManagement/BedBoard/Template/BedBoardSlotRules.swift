import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board slot must pass. Check returns its problems, or none.
    protocol BedBoardSlotRule {
        func check(_ item: BedBoardSlot) -> [String]
    }

    final class BedBoardSlotExpiresAtRangeRule: BedBoardSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardSlot) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardSlotAllowedNameRule: BedBoardSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class BedBoardSlotRegionLengthRule: BedBoardSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardSlot) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardSlotVersionRangeRule: BedBoardSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardSlot) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a bed board slot.
    final class BedBoardSlotValidator {
        var rules: [any BedBoardSlotRule]

        init(rules: [any BedBoardSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardSlot) -> [String] {
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

        func requireValid(_ item: BedBoardSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardSlot]) -> [String: [String]] {
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

    static func defaultBedBoardSlotValidator() -> BedBoardSlotValidator {
        return BedBoardSlotValidator(
            rules: [
                BedBoardSlotExpiresAtRangeRule(min: 64, max: 1000),
                BedBoardSlotAllowedNameRule(allowed: ["fallback", "tiered"]),
                BedBoardSlotRegionLengthRule(maxLength: 255),
                BedBoardSlotVersionRangeRule(min: 32, max: 120),
            ]
        )
    }
}
