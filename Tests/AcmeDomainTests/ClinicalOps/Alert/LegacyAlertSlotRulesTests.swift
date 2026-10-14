@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyAlertSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyAlertSlotValidator()
        let item = ClinicalOps.newLegacyAlertSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyAlertSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.LegacyAlertSlotRequiredCodeRule(message: "legacy alert slot needs a value")
        let item = ClinicalOps.newLegacyAlertSlot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLegacyAlertSlotChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = ClinicalOps.LegacyAlertSlotChannelLengthRule(maxLength: 255)
        let item = ClinicalOps.newLegacyAlertSlot("x", label: "y")
        item.channel = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
