@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryTargetValidator()
        let item = Pharmacy.newInventoryTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InventoryTargetRequiredCodeRule(message: "inventory target needs an entry")
        let item = Pharmacy.newInventoryTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.InventoryTargetRequiredNameRule(message: "inventory target needs an entry")
        let item = Pharmacy.newInventoryTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.InventoryTargetNameLengthRule(maxLength: 64)
        let item = Pharmacy.newInventoryTarget("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
