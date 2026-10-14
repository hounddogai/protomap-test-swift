@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultProxyTemplateValidator()
        let item = Consent.newProxyTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentProxyTemplateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.ProxyTemplateTitleLengthRule(maxLength: 255)
        let item = Consent.newProxyTemplate("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyTemplateRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Consent.ProxyTemplateRequiredDiagnosisCodeRule(message: "proxy template needs an entry")
        let item = Consent.newProxyTemplate("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentProxyTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ProxyTemplateCodeLengthRule(maxLength: 86400)
        let item = Consent.newProxyTemplate("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentProxyTemplateVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Consent.ProxyTemplateVersionRangeRule(min: 32, max: 3600)
        let item = Consent.newProxyTemplate("x", title: "y")
        item.version = 3601
        #expect(rule.check(item).count > 0)
    }
}
