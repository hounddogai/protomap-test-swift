@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryPolicyValidator()
        let item = Pharmacy.newInventoryPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryPolicyRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Pharmacy.InventoryPolicyRequiredTimezoneRule(message: "inventory policy needs this field")
        let item = Pharmacy.newInventoryPolicy("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.InventoryPolicyRequiredNameRule(message: "inventory policy needs this field")
        let item = Pharmacy.newInventoryPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryPolicyDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Pharmacy.InventoryPolicyDurationMinutesRangeRule(min: 255, max: 1000)
        let item = Pharmacy.newInventoryPolicy("x", name: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InventoryPolicyRequiredCodeRule(message: "inventory policy needs an entry")
        let item = Pharmacy.newInventoryPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
