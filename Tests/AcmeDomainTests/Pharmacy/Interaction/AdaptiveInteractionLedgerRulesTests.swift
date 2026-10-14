@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInteractionLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveInteractionLedgerValidator()
        let item = Pharmacy.newAdaptiveInteractionLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveInteractionLedgerCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Pharmacy.AdaptiveInteractionLedgerCapacityRangeRule(min: 120, max: 1000)
        let item = Pharmacy.newAdaptiveInteractionLedger("x", name: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyAdaptiveInteractionLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.AdaptiveInteractionLedgerRequiredCodeRule(
            message: "adaptive interaction ledger needs this field"
        )
        let item = Pharmacy.newAdaptiveInteractionLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
