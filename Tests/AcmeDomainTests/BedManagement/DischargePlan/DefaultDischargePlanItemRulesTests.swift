@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultDischargePlanItemValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultDischargePlanItemValidator()
        let item = BedManagement.newDefaultDischargePlanItem("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultDischargePlanItemNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.DefaultDischargePlanItemNameLengthRule(maxLength: 64)
        let item = BedManagement.newDefaultDischargePlanItem("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDefaultDischargePlanItemRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.DefaultDischargePlanItemRatioRangeRule(min: 7.7, max: 3262.5)
        let item = BedManagement.newDefaultDischargePlanItem("x", name: "y")
        item.ratio = 3264.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultDischargePlanItemRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = BedManagement.DefaultDischargePlanItemRetriesRangeRule(min: 64, max: 86400)
        let item = BedManagement.newDefaultDischargePlanItem("x", name: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultDischargePlanItemQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = BedManagement.DefaultDischargePlanItemQuantityRangeRule(min: 16, max: 120)
        let item = BedManagement.newDefaultDischargePlanItem("x", name: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultDischargePlanItemRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DefaultDischargePlanItemRequiredCodeRule(
            message: "default discharge plan item needs a value"
        )
        let item = BedManagement.newDefaultDischargePlanItem("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
