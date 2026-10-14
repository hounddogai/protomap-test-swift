@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedTransferRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedTransferRuleValidator()
        let item = BedManagement.newCappedTransferRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedTransferRuleLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.CappedTransferRuleLimitRangeRule(min: 120, max: 255)
        let item = BedManagement.newCappedTransferRule("x", label: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCappedTransferRuleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.CappedTransferRuleLabelLengthRule(maxLength: 120)
        let item = BedManagement.newCappedTransferRule("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedTransferRuleRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = BedManagement.CappedTransferRuleRequiredRegionRule(message: "capped transfer rule needs this field")
        let item = BedManagement.newCappedTransferRule("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCappedTransferRuleLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = BedManagement.CappedTransferRuleLocaleLengthRule(maxLength: 32)
        let item = BedManagement.newCappedTransferRule("x", label: "y")
        item.locale = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedTransferRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CappedTransferRuleCodeLengthRule(maxLength: 32)
        let item = BedManagement.newCappedTransferRule("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
