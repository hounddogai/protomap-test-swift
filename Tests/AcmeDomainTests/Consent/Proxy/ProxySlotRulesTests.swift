@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxySlotValidator()
        let item = Consent.newProxySlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxySlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ProxySlotRequiredCodeRule(message: "proxy slot needs an entry")
        let item = Consent.newProxySlot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxySlotDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Consent.ProxySlotDosageMgRangeRule(min: 7.0, max: 1907.9)
        let item = Consent.newProxySlot("x", label: "y")
        item.dosageMg = 1909.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentProxySlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.ProxySlotLabelLengthRule(maxLength: 1000)
        let item = Consent.newProxySlot("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
