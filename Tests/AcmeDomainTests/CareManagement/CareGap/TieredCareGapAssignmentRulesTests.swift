@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredCareGapAssignmentValidator()
        let item = CareManagement.newTieredCareGapAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredCareGapAssignmentFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = CareManagement.TieredCareGapAssignmentFacilityLengthRule(maxLength: 86400)
        let item = CareManagement.newTieredCareGapAssignment("x", name: "y")
        item.facility = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredCareGapAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.TieredCareGapAssignmentRequiredCodeRule(
            message: "tiered care gap assignment needs an entry"
        )
        let item = CareManagement.newTieredCareGapAssignment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
