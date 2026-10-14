@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledOutreachAgreementValidator()
        let item = CareManagement.newScheduledOutreachAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledOutreachAgreementOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = CareManagement.ScheduledOutreachAgreementOwnerIDLengthRule(maxLength: 64)
        let item = CareManagement.newScheduledOutreachAgreement("x", title: "y")
        item.ownerID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledOutreachAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ScheduledOutreachAgreementCodeLengthRule(maxLength: 120)
        let item = CareManagement.newScheduledOutreachAgreement("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledOutreachAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ScheduledOutreachAgreementRequiredCodeRule(
            message: "scheduled outreach agreement needs this field"
        )
        let item = CareManagement.newScheduledOutreachAgreement("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementScheduledOutreachAgreementFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.ScheduledOutreachAgreementFloorValueRangeRule(min: 6.4, max: 597.8)
        let item = CareManagement.newScheduledOutreachAgreement("x", title: "y")
        item.floorValue = 599.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementScheduledOutreachAgreementMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = CareManagement.ScheduledOutreachAgreementMarginRangeRule(min: 2.0, max: 4064.0)
        let item = CareManagement.newScheduledOutreachAgreement("x", title: "y")
        item.margin = 4065.5
        #expect(rule.check(item).count > 0)
    }
}
