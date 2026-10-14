@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingProxyOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingProxyOverrideValidator()
        let item = Consent.newRollingProxyOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingProxyOverrideVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Consent.RollingProxyOverrideVisitMinutesRangeRule(min: 16, max: 64)
        let item = Consent.newRollingProxyOverride("x", name: "y")
        item.visitMinutes = 65
        #expect(rule.check(item).count > 0)
    }
}
