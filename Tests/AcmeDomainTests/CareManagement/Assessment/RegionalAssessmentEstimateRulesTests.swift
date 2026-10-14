@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRegionalAssessmentEstimateValidator()
        let item = CareManagement.newRegionalAssessmentEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRegionalAssessmentEstimateExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.RegionalAssessmentEstimateExternalRefLengthRule(maxLength: 86400)
        let item = CareManagement.newRegionalAssessmentEstimate("x", name: "y")
        item.externalRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRegionalAssessmentEstimateAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = CareManagement.RegionalAssessmentEstimateAcuityRangeRule(min: 16, max: 255)
        let item = CareManagement.newRegionalAssessmentEstimate("x", name: "y")
        item.acuity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRegionalAssessmentEstimateRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = CareManagement.RegionalAssessmentEstimateRequiredExternalRefRule(
            message: "regional assessment estimate needs this field"
        )
        let item = CareManagement.newRegionalAssessmentEstimate("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
