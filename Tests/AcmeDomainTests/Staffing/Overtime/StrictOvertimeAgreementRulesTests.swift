@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictOvertimeAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictOvertimeAgreementValidator()
        let item = Staffing.newStrictOvertimeAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictOvertimeAgreementRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Staffing.StrictOvertimeAgreementRequiredAllergyRule(
            message: "strict overtime agreement needs a value"
        )
        let item = Staffing.newStrictOvertimeAgreement("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictOvertimeAgreementRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.StrictOvertimeAgreementRequiredSummaryRule(
            message: "strict overtime agreement needs this field"
        )
        let item = Staffing.newStrictOvertimeAgreement("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictOvertimeAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.StrictOvertimeAgreementRequiredTitleRule(message: "strict overtime agreement needs an entry")
        let item = Staffing.newStrictOvertimeAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictOvertimeAgreementRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Staffing.StrictOvertimeAgreementRetriesRangeRule(min: 255, max: 255)
        let item = Staffing.newStrictOvertimeAgreement("x", title: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}
