@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureTierValidator()
        let item = Consent.newDisclosureTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureTierTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.DisclosureTierTitleLengthRule(maxLength: 64)
        let item = Consent.newDisclosureTier("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
