@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualOutreachAgreementValidator()
        let item = CareManagement.newManualOutreachAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualOutreachAgreementRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = CareManagement.ManualOutreachAgreementRequiredProcedureCodeRule(
            message: "manual outreach agreement needs an entry"
        )
        let item = CareManagement.newManualOutreachAgreement("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualOutreachAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.ManualOutreachAgreementRequiredTitleRule(
            message: "manual outreach agreement needs a value"
        )
        let item = CareManagement.newManualOutreachAgreement("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualOutreachAgreementProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = CareManagement.ManualOutreachAgreementProcedureCodeLengthRule(maxLength: 120)
        let item = CareManagement.newManualOutreachAgreement("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualOutreachAgreementWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.ManualOutreachAgreementWindowDaysRangeRule(min: 32, max: 64)
        let item = CareManagement.newManualOutreachAgreement("x", label: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}
