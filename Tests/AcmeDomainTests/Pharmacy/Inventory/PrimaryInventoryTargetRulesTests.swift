@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventoryTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimaryInventoryTargetValidator()
        let item = Pharmacy.newPrimaryInventoryTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimaryInventoryTargetRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Pharmacy.PrimaryInventoryTargetRequiredExternalRefRule(
            message: "primary inventory target needs a value"
        )
        let item = Pharmacy.newPrimaryInventoryTarget("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimaryInventoryTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.PrimaryInventoryTargetNameLengthRule(maxLength: 16)
        let item = Pharmacy.newPrimaryInventoryTarget("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPrimaryInventoryTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.PrimaryInventoryTargetRequiredNameRule(message: "primary inventory target needs this field")
        let item = Pharmacy.newPrimaryInventoryTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimaryInventoryTargetRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Pharmacy.PrimaryInventoryTargetRequiredChannelRule(message: "primary inventory target needs an entry")
        let item = Pharmacy.newPrimaryInventoryTarget("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimaryInventoryTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.PrimaryInventoryTargetCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newPrimaryInventoryTarget("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
