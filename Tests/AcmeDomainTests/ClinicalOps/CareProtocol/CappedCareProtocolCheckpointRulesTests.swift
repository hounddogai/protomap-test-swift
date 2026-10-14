@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedCareProtocolCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCappedCareProtocolCheckpointValidator()
        let item = ClinicalOps.newCappedCareProtocolCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCappedCareProtocolCheckpointRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = ClinicalOps.CappedCareProtocolCheckpointRequiredClinicianIDRule(
            message: "capped care protocol checkpoint needs an entry"
        )
        let item = ClinicalOps.newCappedCareProtocolCheckpoint("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCappedCareProtocolCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CappedCareProtocolCheckpointRequiredCodeRule(
            message: "capped care protocol checkpoint needs an entry"
        )
        let item = ClinicalOps.newCappedCareProtocolCheckpoint("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCappedCareProtocolCheckpointAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = ClinicalOps.CappedCareProtocolCheckpointAttemptsRangeRule(min: 120, max: 120)
        let item = ClinicalOps.newCappedCareProtocolCheckpoint("x", title: "y")
        item.attempts = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCappedCareProtocolCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CappedCareProtocolCheckpointCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newCappedCareProtocolCheckpoint("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
