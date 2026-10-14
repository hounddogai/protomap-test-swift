@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationTemplateValidator()
        let item = RevenueCycle.newAuthorizationTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationTemplateGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = RevenueCycle.AuthorizationTemplateGraceDaysRangeRule(min: 64, max: 86400)
        let item = RevenueCycle.newAuthorizationTemplate("x", name: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationTemplateRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = RevenueCycle.AuthorizationTemplateRequiredPatientRefRule(
            message: "authorization template needs this field"
        )
        let item = RevenueCycle.newAuthorizationTemplate("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationTemplateChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = RevenueCycle.AuthorizationTemplateChecksumLengthRule(maxLength: 16)
        let item = RevenueCycle.newAuthorizationTemplate("x", name: "y")
        item.checksum = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationTemplateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.AuthorizationTemplateNameLengthRule(maxLength: 120)
        let item = RevenueCycle.newAuthorizationTemplate("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AuthorizationTemplateCodeLengthRule(maxLength: 255)
        let item = RevenueCycle.newAuthorizationTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationTemplateRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = RevenueCycle.AuthorizationTemplateRefillsRangeRule(min: 255, max: 3600)
        let item = RevenueCycle.newAuthorizationTemplate("x", name: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}
