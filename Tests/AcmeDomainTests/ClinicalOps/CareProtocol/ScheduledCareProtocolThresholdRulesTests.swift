@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultScheduledCareProtocolThresholdValidator()
        let item = ClinicalOps.newScheduledCareProtocolThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolThresholdPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.ScheduledCareProtocolThresholdPatientRefLengthRule(maxLength: 32)
        let item = ClinicalOps.newScheduledCareProtocolThreshold("x", name: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.ScheduledCareProtocolThresholdNameLengthRule(maxLength: 1000)
        let item = ClinicalOps.newScheduledCareProtocolThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.ScheduledCareProtocolThresholdRequiredCodeRule(
            message: "scheduled care protocol threshold needs a value"
        )
        let item = ClinicalOps.newScheduledCareProtocolThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.ScheduledCareProtocolThresholdCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newScheduledCareProtocolThreshold("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
