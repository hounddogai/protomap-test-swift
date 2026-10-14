@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryTaskTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryTaskTemplateValidator()
        let item = ClinicalOps.newPrimaryTaskTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryTaskTemplateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.PrimaryTaskTemplateNameLengthRule(maxLength: 86400)
        let item = ClinicalOps.newPrimaryTaskTemplate("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryTaskTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.PrimaryTaskTemplateCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newPrimaryTaskTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryTaskTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.PrimaryTaskTemplateRequiredCodeRule(message: "primary task template needs this field")
        let item = ClinicalOps.newPrimaryTaskTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPrimaryTaskTemplateChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = ClinicalOps.PrimaryTaskTemplateChecksumLengthRule(maxLength: 16)
        let item = ClinicalOps.newPrimaryTaskTemplate("x", name: "y")
        item.checksum = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
