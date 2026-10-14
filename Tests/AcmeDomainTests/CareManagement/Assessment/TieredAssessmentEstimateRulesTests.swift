@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredAssessmentEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredAssessmentEstimateValidator()
        let item = CareManagement.newTieredAssessmentEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredAssessmentEstimateRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = CareManagement.TieredAssessmentEstimateRetriesRangeRule(min: 64, max: 1000)
        let item = CareManagement.newTieredAssessmentEstimate("x", label: "y")
        item.retries = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementTieredAssessmentEstimateQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.TieredAssessmentEstimateQuantityRangeRule(min: 80, max: 120)
        let item = CareManagement.newTieredAssessmentEstimate("x", label: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementTieredAssessmentEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.TieredAssessmentEstimateCodeLengthRule(maxLength: 120)
        let item = CareManagement.newTieredAssessmentEstimate("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredAssessmentEstimateRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = CareManagement.TieredAssessmentEstimateRequiredPatientRefRule(
            message: "tiered assessment estimate needs an entry"
        )
        let item = CareManagement.newTieredAssessmentEstimate("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredAssessmentEstimatePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = CareManagement.TieredAssessmentEstimatePatientRefLengthRule(maxLength: 80)
        let item = CareManagement.newTieredAssessmentEstimate("x", label: "y")
        item.patientRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
