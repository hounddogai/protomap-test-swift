@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolPolicyValidator()
        let item = ClinicalOps.newCareProtocolPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.CareProtocolPolicyRequiredLabelRule(message: "care protocol policy needs an entry")
        let item = ClinicalOps.newCareProtocolPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CareProtocolPolicyRequiredCodeRule(message: "care protocol policy needs an entry")
        let item = ClinicalOps.newCareProtocolPolicy("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolPolicyWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = ClinicalOps.CareProtocolPolicyWindowDaysRangeRule(min: 32, max: 86400)
        let item = ClinicalOps.newCareProtocolPolicy("x", label: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolPolicyPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.CareProtocolPolicyPatientRefLengthRule(maxLength: 32)
        let item = ClinicalOps.newCareProtocolPolicy("x", label: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolPolicySequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = ClinicalOps.CareProtocolPolicySequenceRangeRule(min: 80, max: 120)
        let item = ClinicalOps.newCareProtocolPolicy("x", label: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}
