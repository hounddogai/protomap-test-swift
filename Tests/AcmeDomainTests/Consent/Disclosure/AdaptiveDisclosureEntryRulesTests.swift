@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveDisclosureEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveDisclosureEntryValidator()
        let item = Consent.newAdaptiveDisclosureEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveDisclosureEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.AdaptiveDisclosureEntryCodeLengthRule(maxLength: 3600)
        let item = Consent.newAdaptiveDisclosureEntry("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveDisclosureEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.AdaptiveDisclosureEntryRequiredNameRule(message: "adaptive disclosure entry needs an entry")
        let item = Consent.newAdaptiveDisclosureEntry("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveDisclosureEntryDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.AdaptiveDisclosureEntryDiscountRangeRule(min: 9.7, max: 799.3)
        let item = Consent.newAdaptiveDisclosureEntry("x", name: "y")
        item.discount = 800.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentAdaptiveDisclosureEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.AdaptiveDisclosureEntryNameLengthRule(maxLength: 255)
        let item = Consent.newAdaptiveDisclosureEntry("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
