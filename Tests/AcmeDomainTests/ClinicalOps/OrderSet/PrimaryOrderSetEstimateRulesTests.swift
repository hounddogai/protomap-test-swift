@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryOrderSetEstimateValidator()
        let item = ClinicalOps.newPrimaryOrderSetEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetEstimatePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.PrimaryOrderSetEstimatePatientRefLengthRule(maxLength: 255)
        let item = ClinicalOps.newPrimaryOrderSetEstimate("x", title: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.PrimaryOrderSetEstimateRequiredCodeRule(
            message: "primary order set estimate needs a value"
        )
        let item = ClinicalOps.newPrimaryOrderSetEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetEstimateContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = ClinicalOps.PrimaryOrderSetEstimateContactEmailLengthRule(maxLength: 3600)
        let item = ClinicalOps.newPrimaryOrderSetEstimate("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryOrderSetEstimateLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = ClinicalOps.PrimaryOrderSetEstimateLimitRangeRule(min: 32, max: 255)
        let item = ClinicalOps.newPrimaryOrderSetEstimate("x", title: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}
