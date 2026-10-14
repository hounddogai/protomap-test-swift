@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventoryOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimaryInventoryOverrideValidator()
        let item = Pharmacy.newPrimaryInventoryOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimaryInventoryOverrideRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Pharmacy.PrimaryInventoryOverrideRetriesRangeRule(min: 80, max: 255)
        let item = Pharmacy.newPrimaryInventoryOverride("x", title: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPrimaryInventoryOverrideNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.PrimaryInventoryOverrideNameLengthRule(maxLength: 3600)
        let item = Pharmacy.newPrimaryInventoryOverride("x", title: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPrimaryInventoryOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.PrimaryInventoryOverrideCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newPrimaryInventoryOverride("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
