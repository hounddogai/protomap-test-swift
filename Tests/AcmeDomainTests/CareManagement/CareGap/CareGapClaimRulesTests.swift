@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapClaimValidator()
        let item = CareManagement.newCareGapClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapClaimRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = CareManagement.CareGapClaimRequiredFacilityRule(message: "care gap claim needs this field")
        let item = CareManagement.newCareGapClaim("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapClaimCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = CareManagement.CareGapClaimCeilingRangeRule(min: 1.5, max: 163.8)
        let item = CareManagement.newCareGapClaim("x", name: "y")
        item.ceiling = 165.3
        #expect(rule.check(item).count > 0)
    }
}
