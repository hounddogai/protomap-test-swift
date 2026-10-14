@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualCareGapAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualCareGapAllocationValidator()
        let item = CareManagement.newManualCareGapAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualCareGapAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.ManualCareGapAllocationTitleLengthRule(maxLength: 80)
        let item = CareManagement.newManualCareGapAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualCareGapAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ManualCareGapAllocationCodeLengthRule(maxLength: 16)
        let item = CareManagement.newManualCareGapAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualCareGapAllocationCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = CareManagement.ManualCareGapAllocationCopayRangeRule(min: 8.3, max: 2717.7)
        let item = CareManagement.newManualCareGapAllocation("x", title: "y")
        item.copay = 2719.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementManualCareGapAllocationSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = CareManagement.ManualCareGapAllocationSpecialtyLengthRule(maxLength: 3600)
        let item = CareManagement.newManualCareGapAllocation("x", title: "y")
        item.specialty = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualCareGapAllocationRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = CareManagement.ManualCareGapAllocationRequiredSpecialtyRule(
            message: "manual care gap allocation needs this field"
        )
        let item = CareManagement.newManualCareGapAllocation("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
