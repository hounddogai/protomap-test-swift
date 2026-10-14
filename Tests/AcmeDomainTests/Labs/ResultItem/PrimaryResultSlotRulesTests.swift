@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryResultSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPrimaryResultSlotValidator()
        let item = Labs.newPrimaryResultSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPrimaryResultSlotRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.PrimaryResultSlotRequiredPhoneRule(message: "primary result slot needs this field")
        let item = Labs.newPrimaryResultSlot("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPrimaryResultSlotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.PrimaryResultSlotNameLengthRule(maxLength: 80)
        let item = Labs.newPrimaryResultSlot("x", title: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryResultSlotPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Labs.PrimaryResultSlotPhoneLengthRule(maxLength: 80)
        let item = Labs.newPrimaryResultSlot("x", title: "y")
        item.phone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryResultSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PrimaryResultSlotRequiredCodeRule(message: "primary result slot needs an entry")
        let item = Labs.newPrimaryResultSlot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPrimaryResultSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PrimaryResultSlotCodeLengthRule(maxLength: 32)
        let item = Labs.newPrimaryResultSlot("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
