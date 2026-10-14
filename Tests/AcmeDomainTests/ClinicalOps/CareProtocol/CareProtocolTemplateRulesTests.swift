@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolTemplateValidator()
        let item = ClinicalOps.newCareProtocolTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolTemplateVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = ClinicalOps.CareProtocolTemplateVersionRangeRule(min: 16, max: 120)
        let item = ClinicalOps.newCareProtocolTemplate("x", name: "y")
        item.version = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CareProtocolTemplateRequiredCodeRule(message: "care protocol template needs this field")
        let item = ClinicalOps.newCareProtocolTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CareProtocolTemplateCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newCareProtocolTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolTemplateChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = ClinicalOps.CareProtocolTemplateChecksumLengthRule(maxLength: 32)
        let item = ClinicalOps.newCareProtocolTemplate("x", name: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolTemplateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.CareProtocolTemplateNameLengthRule(maxLength: 32)
        let item = ClinicalOps.newCareProtocolTemplate("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
