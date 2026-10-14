import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global care protocol snapshot must pass. Check returns its problems, or none.
    protocol GlobalCareProtocolSnapshotRule {
        func check(_ item: GlobalCareProtocolSnapshot) -> [String]
    }

    final class GlobalCareProtocolSnapshotRequiredNameRule: GlobalCareProtocolSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareProtocolSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCareProtocolSnapshotRegionLengthRule: GlobalCareProtocolSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCareProtocolSnapshot) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCareProtocolSnapshotCapacityRangeRule: GlobalCareProtocolSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCareProtocolSnapshot) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global care protocol snapshot.
    final class GlobalCareProtocolSnapshotValidator {
        var rules: [any GlobalCareProtocolSnapshotRule]

        init(rules: [any GlobalCareProtocolSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCareProtocolSnapshot) -> [String] {
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

        func requireValid(_ item: GlobalCareProtocolSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCareProtocolSnapshot]) -> [String: [String]] {
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

    static func defaultGlobalCareProtocolSnapshotValidator() -> GlobalCareProtocolSnapshotValidator {
        return GlobalCareProtocolSnapshotValidator(
            rules: [
                GlobalCareProtocolSnapshotRequiredNameRule(message: "global care protocol snapshot needs this field"),
                GlobalCareProtocolSnapshotRegionLengthRule(maxLength: 64),
                GlobalCareProtocolSnapshotCapacityRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
