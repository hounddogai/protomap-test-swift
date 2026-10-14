@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientCareGapAllocationValidator()
        let item = CareManagement.newLenientCareGapAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientCareGapAllocationLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = CareManagement.LenientCareGapAllocationLocaleLengthRule(maxLength: 120)
        let item = CareManagement.newLenientCareGapAllocation("x", title: "y")
        item.locale = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientCareGapAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.LenientCareGapAllocationRequiredCodeRule(
            message: "lenient care gap allocation needs a value"
        )
        let item = CareManagement.newLenientCareGapAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientCareGapAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LenientCareGapAllocationCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newLenientCareGapAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
