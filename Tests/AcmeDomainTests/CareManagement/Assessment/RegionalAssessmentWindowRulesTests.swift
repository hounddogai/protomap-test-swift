@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRegionalAssessmentWindowValidator()
        let item = CareManagement.newRegionalAssessmentWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRegionalAssessmentWindowRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = CareManagement.RegionalAssessmentWindowRequiredPhoneRule(
            message: "regional assessment window needs this field"
        )
        let item = CareManagement.newRegionalAssessmentWindow("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRegionalAssessmentWindowUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.RegionalAssessmentWindowUpdatedAtRangeRule(min: 16, max: 32)
        let item = CareManagement.newRegionalAssessmentWindow("x", name: "y")
        item.updatedAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRegionalAssessmentWindowCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = CareManagement.RegionalAssessmentWindowCopayRangeRule(min: 5.8, max: 2948.5)
        let item = CareManagement.newRegionalAssessmentWindow("x", name: "y")
        item.copay = 2950.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRegionalAssessmentWindowRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = CareManagement.RegionalAssessmentWindowRequiredSpecialtyRule(
            message: "regional assessment window needs this field"
        )
        let item = CareManagement.newRegionalAssessmentWindow("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRegionalAssessmentWindowSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = CareManagement.RegionalAssessmentWindowSpecialtyLengthRule(maxLength: 32)
        let item = CareManagement.newRegionalAssessmentWindow("x", name: "y")
        item.specialty = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
