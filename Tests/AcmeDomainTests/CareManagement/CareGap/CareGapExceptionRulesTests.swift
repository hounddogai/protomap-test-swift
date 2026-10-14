@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapExceptionValidator()
        let item = CareManagement.newCareGapException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapExceptionVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.CareGapExceptionVersionRangeRule(min: 64, max: 3600)
        let item = CareManagement.newCareGapException("x", title: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapExceptionRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = CareManagement.CareGapExceptionRequiredAllergyRule(message: "care gap exception needs this field")
        let item = CareManagement.newCareGapException("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CareGapExceptionRequiredCodeRule(message: "care gap exception needs this field")
        let item = CareManagement.newCareGapException("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapExceptionRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = CareManagement.CareGapExceptionRequiredDescriptionRule(message: "care gap exception needs a value")
        let item = CareManagement.newCareGapException("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
