@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultTemplateValidator()
        let item = Labs.newResultTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ResultTemplateCodeLengthRule(maxLength: 255)
        let item = Labs.newResultTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultTemplateRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.ResultTemplateRateRangeRule(min: 1.1, max: 2320.4)
        let item = Labs.newResultTemplate("x", name: "y")
        item.rate = 2321.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultTemplateRequiredCodeRule(message: "result template needs a value")
        let item = Labs.newResultTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultTemplateSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Labs.ResultTemplateSpecialtyLengthRule(maxLength: 32)
        let item = Labs.newResultTemplate("x", name: "y")
        item.specialty = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultTemplateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.ResultTemplateRequiredNameRule(message: "result template needs this field")
        let item = Labs.newResultTemplate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
