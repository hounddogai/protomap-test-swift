import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient remittance slot must pass. Check returns its problems, or none.
    protocol LenientRemittanceSlotRule {
        func check(_ item: LenientRemittanceSlot) -> [String]
    }

    final class LenientRemittanceSlotSegmentLengthRule: LenientRemittanceSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRemittanceSlot) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRemittanceSlotAllowedRegionRule: LenientRemittanceSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientRemittanceSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is above maximum"]
            }
            return []
        }
    }

    final class LenientRemittanceSlotRegionLengthRule: LenientRemittanceSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRemittanceSlot) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRemittanceSlotCodePrefixRule: LenientRemittanceSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientRemittanceSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient remittance slot.
    final class LenientRemittanceSlotValidator {
        var rules: [any LenientRemittanceSlotRule]

        init(rules: [any LenientRemittanceSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRemittanceSlot) -> [String] {
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

        func requireValid(_ item: LenientRemittanceSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRemittanceSlot]) -> [String: [String]] {
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

    static func defaultLenientRemittanceSlotValidator() -> LenientRemittanceSlotValidator {
        return LenientRemittanceSlotValidator(
            rules: [
                LenientRemittanceSlotSegmentLengthRule(maxLength: 3600),
                LenientRemittanceSlotAllowedRegionRule(allowed: []),
                LenientRemittanceSlotRegionLengthRule(maxLength: 120),
                LenientRemittanceSlotCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
