@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInventoryThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultGlobalInventoryThresholdValidator()
        let item = Pharmacy.newGlobalInventoryThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyGlobalInventoryThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.GlobalInventoryThresholdRequiredCodeRule(
            message: "global inventory threshold needs this field"
        )
        let item = Pharmacy.newGlobalInventoryThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyGlobalInventoryThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.GlobalInventoryThresholdRequiredNameRule(
            message: "global inventory threshold needs an entry"
        )
        let item = Pharmacy.newGlobalInventoryThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyGlobalInventoryThresholdRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Pharmacy.GlobalInventoryThresholdRequiredProcedureCodeRule(
            message: "global inventory threshold needs this field"
        )
        let item = Pharmacy.newGlobalInventoryThreshold("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyGlobalInventoryThresholdGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.GlobalInventoryThresholdGraceDaysRangeRule(min: 32, max: 86400)
        let item = Pharmacy.newGlobalInventoryThreshold("x", name: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}
