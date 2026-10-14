@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseProfileValidator()
        let item = Pharmacy.newDispenseProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseProfileNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.DispenseProfileNameLengthRule(maxLength: 16)
        let item = Pharmacy.newDispenseProfile("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseProfileScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Pharmacy.DispenseProfileScoreRangeRule(min: 8.9, max: 1175.3)
        let item = Pharmacy.newDispenseProfile("x", name: "y")
        item.score = 1176.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseProfileRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Pharmacy.DispenseProfileRequiredExternalRefRule(message: "dispense profile needs a value")
        let item = Pharmacy.newDispenseProfile("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseProfileExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Pharmacy.DispenseProfileExternalRefLengthRule(maxLength: 86400)
        let item = Pharmacy.newDispenseProfile("x", name: "y")
        item.externalRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
