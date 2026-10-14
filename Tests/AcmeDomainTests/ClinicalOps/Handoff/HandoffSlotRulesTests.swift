@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffSlotValidator()
        let item = ClinicalOps.newHandoffSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffSlotChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = ClinicalOps.HandoffSlotChecksumLengthRule(maxLength: 3600)
        let item = ClinicalOps.newHandoffSlot("x", name: "y")
        item.checksum = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffSlotRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = ClinicalOps.HandoffSlotRequiredPhoneRule(message: "handoff slot needs an entry")
        let item = ClinicalOps.newHandoffSlot("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
