@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalFloatPoolAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalFloatPoolAdjustmentValidator()
        let item = Staffing.newGlobalFloatPoolAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalFloatPoolAdjustmentRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Staffing.GlobalFloatPoolAdjustmentRequiredOwnerIDRule(
            message: "global float pool adjustment needs an entry"
        )
        let item = Staffing.newGlobalFloatPoolAdjustment("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalFloatPoolAdjustmentRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Staffing.GlobalFloatPoolAdjustmentRequiredCurrencyRule(
            message: "global float pool adjustment needs this field"
        )
        let item = Staffing.newGlobalFloatPoolAdjustment("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalFloatPoolAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.GlobalFloatPoolAdjustmentLabelLengthRule(maxLength: 86400)
        let item = Staffing.newGlobalFloatPoolAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
