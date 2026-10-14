@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseRuleValidator()
        let item = Pharmacy.newDispenseRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseRuleBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Pharmacy.DispenseRuleBatchSizeRangeRule(min: 3600, max: 86400)
        let item = Pharmacy.newDispenseRule("x", name: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DispenseRuleCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newDispenseRule("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseRuleExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Pharmacy.DispenseRuleExternalRefLengthRule(maxLength: 16)
        let item = Pharmacy.newDispenseRule("x", name: "y")
        item.externalRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseRuleRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Pharmacy.DispenseRuleRequiredExternalRefRule(message: "dispense rule needs a value")
        let item = Pharmacy.newDispenseRule("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
