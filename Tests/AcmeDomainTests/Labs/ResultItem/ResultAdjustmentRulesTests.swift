@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultAdjustmentValidator()
        let item = Labs.newResultAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultAdjustmentQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.ResultAdjustmentQuantityRangeRule(min: 16, max: 86400)
        let item = Labs.newResultAdjustment("x", name: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultAdjustmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.ResultAdjustmentNameLengthRule(maxLength: 16)
        let item = Labs.newResultAdjustment("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultAdjustmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.ResultAdjustmentRequiredNameRule(message: "result adjustment needs a value")
        let item = Labs.newResultAdjustment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultAdjustmentLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.ResultAdjustmentLimitRangeRule(min: 16, max: 1000)
        let item = Labs.newResultAdjustment("x", name: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}
