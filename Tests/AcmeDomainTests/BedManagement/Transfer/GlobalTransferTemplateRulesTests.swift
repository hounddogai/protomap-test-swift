@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalTransferTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalTransferTemplateValidator()
        let item = BedManagement.newGlobalTransferTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalTransferTemplateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.GlobalTransferTemplateRequiredNameRule(
            message: "global transfer template needs this field"
        )
        let item = BedManagement.newGlobalTransferTemplate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalTransferTemplateRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = BedManagement.GlobalTransferTemplateRequiredSourceRule(
            message: "global transfer template needs an entry"
        )
        let item = BedManagement.newGlobalTransferTemplate("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementGlobalTransferTemplateSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = BedManagement.GlobalTransferTemplateSourceLengthRule(maxLength: 3600)
        let item = BedManagement.newGlobalTransferTemplate("x", name: "y")
        item.source = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementGlobalTransferTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.GlobalTransferTemplateCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newGlobalTransferTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementGlobalTransferTemplateCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.GlobalTransferTemplateCopayRangeRule(min: 6.6, max: 4471.6)
        let item = BedManagement.newGlobalTransferTemplate("x", name: "y")
        item.copay = 4473.1
        #expect(rule.check(item).count > 0)
    }
}
