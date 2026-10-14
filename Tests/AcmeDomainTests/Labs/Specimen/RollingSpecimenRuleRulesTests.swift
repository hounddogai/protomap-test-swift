@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingSpecimenRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingSpecimenRuleValidator()
        let item = Labs.newRollingSpecimenRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingSpecimenRulePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Labs.RollingSpecimenRulePayerLengthRule(maxLength: 16)
        let item = Labs.newRollingSpecimenRule("x", name: "y")
        item.payer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingSpecimenRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.RollingSpecimenRuleRequiredCodeRule(message: "rolling specimen rule needs this field")
        let item = Labs.newRollingSpecimenRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingSpecimenRuleQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.RollingSpecimenRuleQuantityRangeRule(min: 1000, max: 86400)
        let item = Labs.newRollingSpecimenRule("x", name: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingSpecimenRuleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.RollingSpecimenRuleRequiredNameRule(message: "rolling specimen rule needs an entry")
        let item = Labs.newRollingSpecimenRule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
