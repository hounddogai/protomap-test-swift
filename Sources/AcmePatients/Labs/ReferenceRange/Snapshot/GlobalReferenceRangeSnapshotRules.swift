import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global reference range snapshot must pass. Check returns its problems, or none.
    protocol GlobalReferenceRangeSnapshotRule {
        func check(_ item: GlobalReferenceRangeSnapshot) -> [String]
    }

    final class GlobalReferenceRangeSnapshotWindowDaysRangeRule: GlobalReferenceRangeSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReferenceRangeSnapshot) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalReferenceRangeSnapshotCapacityRangeRule: GlobalReferenceRangeSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReferenceRangeSnapshot) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalReferenceRangeSnapshotClinicianIDLengthRule: GlobalReferenceRangeSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReferenceRangeSnapshot) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalReferenceRangeSnapshotRequiredLabelRule: GlobalReferenceRangeSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReferenceRangeSnapshot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReferenceRangeSnapshotAllowedClinicianIDRule: GlobalReferenceRangeSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalReferenceRangeSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a global reference range snapshot.
    final class GlobalReferenceRangeSnapshotValidator {
        var rules: [any GlobalReferenceRangeSnapshotRule]

        init(rules: [any GlobalReferenceRangeSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalReferenceRangeSnapshot) -> [String] {
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

        func requireValid(_ item: GlobalReferenceRangeSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalReferenceRangeSnapshot]) -> [String: [String]] {
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

    static func defaultGlobalReferenceRangeSnapshotValidator() -> GlobalReferenceRangeSnapshotValidator {
        return GlobalReferenceRangeSnapshotValidator(
            rules: [
                GlobalReferenceRangeSnapshotWindowDaysRangeRule(min: 1000, max: 86400),
                GlobalReferenceRangeSnapshotCapacityRangeRule(min: 64, max: 80),
                GlobalReferenceRangeSnapshotClinicianIDLengthRule(maxLength: 86400),
                GlobalReferenceRangeSnapshotRequiredLabelRule(
                    message: "global reference range snapshot needs a value"
                ),
                GlobalReferenceRangeSnapshotAllowedClinicianIDRule(allowed: []),
            ]
        )
    }
}
