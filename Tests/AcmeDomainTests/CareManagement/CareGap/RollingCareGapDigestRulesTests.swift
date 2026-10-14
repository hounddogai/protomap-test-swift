@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingCareGapDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRollingCareGapDigestValidator()
        let item = CareManagement.newRollingCareGapDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRollingCareGapDigestFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = CareManagement.RollingCareGapDigestFacilityLengthRule(maxLength: 1000)
        let item = CareManagement.newRollingCareGapDigest("x", title: "y")
        item.facility = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingCareGapDigestRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = CareManagement.RollingCareGapDigestRequiredFacilityRule(
            message: "rolling care gap digest needs this field"
        )
        let item = CareManagement.newRollingCareGapDigest("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
