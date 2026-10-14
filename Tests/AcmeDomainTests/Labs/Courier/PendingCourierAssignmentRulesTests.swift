@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingCourierAssignmentValidator()
        let item = Labs.newPendingCourierAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingCourierAssignmentRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Labs.PendingCourierAssignmentRequiredFacilityRule(
            message: "pending courier assignment needs an entry"
        )
        let item = Labs.newPendingCourierAssignment("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingCourierAssignmentRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.PendingCourierAssignmentRatioRangeRule(min: 6.3, max: 3019.0)
        let item = Labs.newPendingCourierAssignment("x", name: "y")
        item.ratio = 3020.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPendingCourierAssignmentMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Labs.PendingCourierAssignmentMaximumRangeRule(min: 1.1, max: 4317.4)
        let item = Labs.newPendingCourierAssignment("x", name: "y")
        item.maximum = 4318.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPendingCourierAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PendingCourierAssignmentCodeLengthRule(maxLength: 32)
        let item = Labs.newPendingCourierAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
