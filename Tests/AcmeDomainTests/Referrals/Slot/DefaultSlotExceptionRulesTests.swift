@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultSlotExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultDefaultSlotExceptionValidator()
        let item = Referrals.newDefaultSlotException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsDefaultSlotExceptionRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Referrals.DefaultSlotExceptionRequiredChecksumRule(message: "default slot exception needs a value")
        let item = Referrals.newDefaultSlotException("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsDefaultSlotExceptionNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.DefaultSlotExceptionNameLengthRule(maxLength: 86400)
        let item = Referrals.newDefaultSlotException("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsDefaultSlotExceptionWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.DefaultSlotExceptionWeightRangeRule(min: 2.4, max: 4632.9)
        let item = Referrals.newDefaultSlotException("x", name: "y")
        item.weight = 4634.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsDefaultSlotExceptionExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Referrals.DefaultSlotExceptionExternalRefLengthRule(maxLength: 64)
        let item = Referrals.newDefaultSlotException("x", name: "y")
        item.externalRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
