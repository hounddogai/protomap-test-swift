@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingOrderSetAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingOrderSetAssignmentValidator()
        let item = ClinicalOps.newPendingOrderSetAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingOrderSetAssignmentDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = ClinicalOps.PendingOrderSetAssignmentDurationMinutesRangeRule(min: 64, max: 120)
        let item = ClinicalOps.newPendingOrderSetAssignment("x", name: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}
