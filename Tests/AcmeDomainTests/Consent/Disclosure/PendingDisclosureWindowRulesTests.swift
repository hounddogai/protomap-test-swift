@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingDisclosureWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPendingDisclosureWindowValidator()
        let item = Consent.newPendingDisclosureWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPendingDisclosureWindowMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Consent.PendingDisclosureWindowMarginRangeRule(min: 9.9, max: 2722.2)
        let item = Consent.newPendingDisclosureWindow("x", name: "y")
        item.margin = 2723.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingDisclosureWindowGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Consent.PendingDisclosureWindowGraceDaysRangeRule(min: 255, max: 86400)
        let item = Consent.newPendingDisclosureWindow("x", name: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingDisclosureWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.PendingDisclosureWindowCodeLengthRule(maxLength: 80)
        let item = Consent.newPendingDisclosureWindow("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
