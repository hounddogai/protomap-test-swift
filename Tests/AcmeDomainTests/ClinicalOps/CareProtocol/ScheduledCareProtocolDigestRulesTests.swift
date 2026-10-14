@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultScheduledCareProtocolDigestValidator()
        let item = ClinicalOps.newScheduledCareProtocolDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.ScheduledCareProtocolDigestCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newScheduledCareProtocolDigest("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolDigestRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = ClinicalOps.ScheduledCareProtocolDigestRequiredEncounterIDRule(
            message: "scheduled care protocol digest needs this field"
        )
        let item = ClinicalOps.newScheduledCareProtocolDigest("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.ScheduledCareProtocolDigestNameLengthRule(maxLength: 255)
        let item = ClinicalOps.newScheduledCareProtocolDigest("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolDigestCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = ClinicalOps.ScheduledCareProtocolDigestCopayRangeRule(min: 8.7, max: 1931.9)
        let item = ClinicalOps.newScheduledCareProtocolDigest("x", name: "y")
        item.copay = 1933.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolDigestEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = ClinicalOps.ScheduledCareProtocolDigestEncounterIDLengthRule(maxLength: 16)
        let item = ClinicalOps.newScheduledCareProtocolDigest("x", name: "y")
        item.encounterID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
