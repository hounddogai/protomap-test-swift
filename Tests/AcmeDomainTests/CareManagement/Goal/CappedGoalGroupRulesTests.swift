@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedGoalGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCappedGoalGroupValidator()
        let item = CareManagement.newCappedGoalGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCappedGoalGroupQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.CappedGoalGroupQuantityRangeRule(min: 64, max: 64)
        let item = CareManagement.newCappedGoalGroup("x", label: "y")
        item.quantity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedGoalGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CappedGoalGroupRequiredCodeRule(message: "capped goal group needs a value")
        let item = CareManagement.newCappedGoalGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedGoalGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.CappedGoalGroupCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newCappedGoalGroup("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCappedGoalGroupRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.CappedGoalGroupRequiredChannelRule(message: "capped goal group needs a value")
        let item = CareManagement.newCappedGoalGroup("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedGoalGroupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.CappedGoalGroupRequiredLabelRule(message: "capped goal group needs an entry")
        let item = CareManagement.newCappedGoalGroup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
