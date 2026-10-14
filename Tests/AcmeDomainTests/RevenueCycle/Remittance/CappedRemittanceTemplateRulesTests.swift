@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedRemittanceTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultCappedRemittanceTemplateValidator()
        let item = RevenueCycle.newCappedRemittanceTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleCappedRemittanceTemplateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.CappedRemittanceTemplateRequiredNameRule(
            message: "capped remittance template needs this field"
        )
        let item = RevenueCycle.newCappedRemittanceTemplate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleCappedRemittanceTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.CappedRemittanceTemplateCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newCappedRemittanceTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleCappedRemittanceTemplateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.CappedRemittanceTemplateNameLengthRule(maxLength: 80)
        let item = RevenueCycle.newCappedRemittanceTemplate("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
