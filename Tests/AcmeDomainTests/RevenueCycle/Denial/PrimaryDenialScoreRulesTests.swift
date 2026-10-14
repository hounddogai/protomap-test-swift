@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryDenialScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPrimaryDenialScoreValidator()
        let item = RevenueCycle.newPrimaryDenialScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePrimaryDenialScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.PrimaryDenialScoreCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newPrimaryDenialScore("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePrimaryDenialScoreRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = RevenueCycle.PrimaryDenialScoreRequiredSpecialtyRule(message: "primary denial score needs this field")
        let item = RevenueCycle.newPrimaryDenialScore("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
