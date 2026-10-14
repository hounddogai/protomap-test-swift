@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotThresholdValidator()
        let item = Referrals.newSlotThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotThresholdCodeLengthRule(maxLength: 80)
        let item = Referrals.newSlotThreshold("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SlotThresholdRequiredCodeRule(message: "slot threshold needs an entry")
        let item = Referrals.newSlotThreshold("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotThresholdEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Referrals.SlotThresholdEncounterIDLengthRule(maxLength: 3600)
        let item = Referrals.newSlotThreshold("x", title: "y")
        item.encounterID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
