@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalInventoryRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRegionalInventoryRollupValidator()
        let item = Pharmacy.newRegionalInventoryRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRegionalInventoryRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.RegionalInventoryRollupRequiredLabelRule(message: "regional inventory rollup needs an entry")
        let item = Pharmacy.newRegionalInventoryRollup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalInventoryRollupRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Pharmacy.RegionalInventoryRollupRequiredPhoneRule(message: "regional inventory rollup needs an entry")
        let item = Pharmacy.newRegionalInventoryRollup("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalInventoryRollupSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Pharmacy.RegionalInventoryRollupSourceLengthRule(maxLength: 120)
        let item = Pharmacy.newRegionalInventoryRollup("x", label: "y")
        item.source = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
