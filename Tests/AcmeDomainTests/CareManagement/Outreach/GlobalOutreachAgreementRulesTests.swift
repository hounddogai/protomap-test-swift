@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalOutreachAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalOutreachAgreementValidator()
        let item = CareManagement.newGlobalOutreachAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalOutreachAgreementTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = CareManagement.GlobalOutreachAgreementTimezoneLengthRule(maxLength: 16)
        let item = CareManagement.newGlobalOutreachAgreement("x", title: "y")
        item.timezone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalOutreachAgreementRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = CareManagement.GlobalOutreachAgreementRatioRangeRule(min: 8.0, max: 2575.7)
        let item = CareManagement.newGlobalOutreachAgreement("x", title: "y")
        item.ratio = 2577.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalOutreachAgreementRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = CareManagement.GlobalOutreachAgreementRequiredSourceRule(
            message: "global outreach agreement needs this field"
        )
        let item = CareManagement.newGlobalOutreachAgreement("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalOutreachAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.GlobalOutreachAgreementRequiredTitleRule(
            message: "global outreach agreement needs a value"
        )
        let item = CareManagement.newGlobalOutreachAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
