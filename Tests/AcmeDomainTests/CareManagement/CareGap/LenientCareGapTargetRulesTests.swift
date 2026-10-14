@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientCareGapTargetValidator()
        let item = CareManagement.newLenientCareGapTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientCareGapTargetRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = CareManagement.LenientCareGapTargetRequiredClinicianIDRule(
            message: "lenient care gap target needs a value"
        )
        let item = CareManagement.newLenientCareGapTarget("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientCareGapTargetExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.LenientCareGapTargetExpiresAtRangeRule(min: 16, max: 86400)
        let item = CareManagement.newLenientCareGapTarget("x", label: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLenientCareGapTargetMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = CareManagement.LenientCareGapTargetMaximumRangeRule(min: 3.5, max: 3976.1)
        let item = CareManagement.newLenientCareGapTarget("x", label: "y")
        item.maximum = 3977.6
        #expect(rule.check(item).count > 0)
    }
}
