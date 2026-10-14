import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary worklist snapshot must pass. Check returns its problems, or none.
    protocol PrimaryWorklistSnapshotRule {
        func check(_ item: PrimaryWorklistSnapshot) -> [String]
    }

    final class PrimaryWorklistSnapshotDiscountRangeRule: PrimaryWorklistSnapshotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryWorklistSnapshot) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryWorklistSnapshotRequiredProcedureCodeRule: PrimaryWorklistSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryWorklistSnapshot) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryWorklistSnapshotProcedureCodeLengthRule: PrimaryWorklistSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryWorklistSnapshot) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary worklist snapshot.
    final class PrimaryWorklistSnapshotValidator {
        var rules: [any PrimaryWorklistSnapshotRule]

        init(rules: [any PrimaryWorklistSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryWorklistSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryWorklistSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryWorklistSnapshot]) -> [String: [String]] {
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

    static func defaultPrimaryWorklistSnapshotValidator() -> PrimaryWorklistSnapshotValidator {
        return PrimaryWorklistSnapshotValidator(
            rules: [
                PrimaryWorklistSnapshotDiscountRangeRule(min: 7.9, max: 4490.3),
                PrimaryWorklistSnapshotRequiredProcedureCodeRule(message: "primary worklist snapshot needs a value"),
                PrimaryWorklistSnapshotProcedureCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
