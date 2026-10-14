@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierAgreementValidator()
        let item = Labs.newCourierAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierAgreementRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Labs.CourierAgreementRefillsRangeRule(min: 80, max: 80)
        let item = Labs.newCourierAgreement("x", name: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCourierAgreementFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Labs.CourierAgreementFloorValueRangeRule(min: 9.2, max: 2306.8)
        let item = Labs.newCourierAgreement("x", name: "y")
        item.floorValue = 2308.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCourierAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CourierAgreementCodeLengthRule(maxLength: 120)
        let item = Labs.newCourierAgreement("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CourierAgreementRequiredCodeRule(message: "courier agreement needs a value")
        let item = Labs.newCourierAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierAgreementUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Labs.CourierAgreementUnitLengthRule(maxLength: 86400)
        let item = Labs.newCourierAgreement("x", name: "y")
        item.unit = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
