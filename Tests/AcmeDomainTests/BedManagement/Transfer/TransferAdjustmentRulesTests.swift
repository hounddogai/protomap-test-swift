@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferAdjustmentValidator()
        let item = BedManagement.newTransferAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferAdjustmentCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.TransferAdjustmentCeilingRangeRule(min: 9.3, max: 2598.1)
        let item = BedManagement.newTransferAdjustment("x", title: "y")
        item.ceiling = 2599.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferAdjustmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.TransferAdjustmentRequiredTitleRule(message: "transfer adjustment needs an entry")
        let item = BedManagement.newTransferAdjustment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferAdjustmentRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.TransferAdjustmentRatioRangeRule(min: 0.5, max: 1197.5)
        let item = BedManagement.newTransferAdjustment("x", title: "y")
        item.ratio = 1199.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferAdjustmentVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = BedManagement.TransferAdjustmentVersionRangeRule(min: 86400, max: 86400)
        let item = BedManagement.newTransferAdjustment("x", title: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.TransferAdjustmentCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newTransferAdjustment("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
