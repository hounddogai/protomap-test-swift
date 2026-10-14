import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan snapshot must pass. Check returns its problems, or none.
    protocol AcuityPlanSnapshotRule {
        func check(_ item: AcuityPlanSnapshot) -> [String]
    }

    final class AcuityPlanSnapshotNameLengthRule: AcuityPlanSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanSnapshot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanSnapshotPhoneLengthRule: AcuityPlanSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanSnapshot) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanSnapshotRequiredSegmentRule: AcuityPlanSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanSnapshot) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanSnapshotRequiredNameRule: AcuityPlanSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan snapshot.
    final class AcuityPlanSnapshotValidator {
        var rules: [any AcuityPlanSnapshotRule]

        init(rules: [any AcuityPlanSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanSnapshot) -> [String] {
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

        func requireValid(_ item: AcuityPlanSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanSnapshot]) -> [String: [String]] {
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

    static func defaultAcuityPlanSnapshotValidator() -> AcuityPlanSnapshotValidator {
        return AcuityPlanSnapshotValidator(
            rules: [
                AcuityPlanSnapshotNameLengthRule(maxLength: 64),
                AcuityPlanSnapshotPhoneLengthRule(maxLength: 3600),
                AcuityPlanSnapshotRequiredSegmentRule(message: "acuity plan snapshot needs a value"),
                AcuityPlanSnapshotRequiredNameRule(message: "acuity plan snapshot needs a value"),
            ]
        )
    }
}
