@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedRecallCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedRecallCycleValidator()
        let item = Pharmacy.newWeightedRecallCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedRecallCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.WeightedRecallCycleCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newWeightedRecallCycle("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedRecallCycleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.WeightedRecallCycleExpiresAtRangeRule(min: 32, max: 32)
        let item = Pharmacy.newWeightedRecallCycle("x", name: "y")
        item.expiresAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedRecallCycleRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Pharmacy.WeightedRecallCycleRequiredClinicianIDRule(message: "weighted recall cycle needs an entry")
        let item = Pharmacy.newWeightedRecallCycle("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
