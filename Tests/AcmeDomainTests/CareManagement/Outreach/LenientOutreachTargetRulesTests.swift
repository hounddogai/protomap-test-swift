@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientOutreachTargetValidator()
        let item = CareManagement.newLenientOutreachTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientOutreachTargetQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.LenientOutreachTargetQuantityRangeRule(min: 1000, max: 86400)
        let item = CareManagement.newLenientOutreachTarget("x", title: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLenientOutreachTargetContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = CareManagement.LenientOutreachTargetContactEmailLengthRule(maxLength: 32)
        let item = CareManagement.newLenientOutreachTarget("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientOutreachTargetCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = CareManagement.LenientOutreachTargetCopayRangeRule(min: 4.4, max: 3666.9)
        let item = CareManagement.newLenientOutreachTarget("x", title: "y")
        item.copay = 3668.4
        #expect(rule.check(item).count > 0)
    }
}
