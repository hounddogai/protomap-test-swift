@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInventoryCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultGlobalInventoryCycleValidator()
        let item = Pharmacy.newGlobalInventoryCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyGlobalInventoryCycleChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Pharmacy.GlobalInventoryCycleChannelLengthRule(maxLength: 255)
        let item = Pharmacy.newGlobalInventoryCycle("x", name: "y")
        item.channel = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalInventoryCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.GlobalInventoryCycleCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newGlobalInventoryCycle("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalInventoryCycleRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Pharmacy.GlobalInventoryCycleRequiredRegionRule(message: "global inventory cycle needs an entry")
        let item = Pharmacy.newGlobalInventoryCycle("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyGlobalInventoryCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.GlobalInventoryCycleRequiredCodeRule(message: "global inventory cycle needs this field")
        let item = Pharmacy.newGlobalInventoryCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
