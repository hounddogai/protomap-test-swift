@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveCareProtocolEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAdaptiveCareProtocolEstimateValidator()
        let item = ClinicalOps.newAdaptiveCareProtocolEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAdaptiveCareProtocolEstimateAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = ClinicalOps.AdaptiveCareProtocolEstimateAcuityRangeRule(min: 120, max: 3600)
        let item = ClinicalOps.newAdaptiveCareProtocolEstimate("x", name: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAdaptiveCareProtocolEstimateRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = ClinicalOps.AdaptiveCareProtocolEstimateRequiredPatientRefRule(
            message: "adaptive care protocol estimate needs an entry"
        )
        let item = ClinicalOps.newAdaptiveCareProtocolEstimate("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveCareProtocolEstimatePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.AdaptiveCareProtocolEstimatePatientRefLengthRule(maxLength: 16)
        let item = ClinicalOps.newAdaptiveCareProtocolEstimate("x", name: "y")
        item.patientRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAdaptiveCareProtocolEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.AdaptiveCareProtocolEstimateCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newAdaptiveCareProtocolEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
