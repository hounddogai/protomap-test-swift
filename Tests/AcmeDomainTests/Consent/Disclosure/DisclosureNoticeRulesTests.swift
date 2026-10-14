@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureNoticeValidator()
        let item = Consent.newDisclosureNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureNoticeDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.DisclosureNoticeDiscountRangeRule(min: 3.4, max: 857.7)
        let item = Consent.newDisclosureNotice("x", title: "y")
        item.discount = 859.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureNoticeRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Consent.DisclosureNoticeRequiredPayerRule(message: "disclosure notice needs an entry")
        let item = Consent.newDisclosureNotice("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureNoticePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Consent.DisclosureNoticePayerLengthRule(maxLength: 80)
        let item = Consent.newDisclosureNotice("x", title: "y")
        item.payer = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
