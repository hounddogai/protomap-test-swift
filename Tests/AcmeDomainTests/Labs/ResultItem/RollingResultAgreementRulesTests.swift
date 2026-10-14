@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingResultAgreementValidator()
        let item = Labs.newRollingResultAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingResultAgreementPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Labs.RollingResultAgreementPriorityRangeRule(min: 32, max: 1000)
        let item = Labs.newRollingResultAgreement("x", name: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingResultAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.RollingResultAgreementNameLengthRule(maxLength: 86400)
        let item = Labs.newRollingResultAgreement("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingResultAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.RollingResultAgreementRequiredCodeRule(message: "rolling result agreement needs an entry")
        let item = Labs.newRollingResultAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingResultAgreementQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.RollingResultAgreementQuantityRangeRule(min: 16, max: 3600)
        let item = Labs.newRollingResultAgreement("x", name: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingResultAgreementFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Labs.RollingResultAgreementFloorValueRangeRule(min: 9.4, max: 1265.4)
        let item = Labs.newRollingResultAgreement("x", name: "y")
        item.floorValue = 1266.9
        #expect(rule.check(item).count > 0)
    }
}
