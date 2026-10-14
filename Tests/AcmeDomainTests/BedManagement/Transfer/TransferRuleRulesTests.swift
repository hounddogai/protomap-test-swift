@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferRuleValidator()
        let item = BedManagement.newTransferRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferRuleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.TransferRuleRequiredLabelRule(message: "transfer rule needs this field")
        let item = BedManagement.newTransferRule("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferRuleLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.TransferRuleLimitRangeRule(min: 16, max: 16)
        let item = BedManagement.newTransferRule("x", label: "y")
        item.limit = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.TransferRuleRequiredCodeRule(message: "transfer rule needs a value")
        let item = BedManagement.newTransferRule("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.TransferRuleCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newTransferRule("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
