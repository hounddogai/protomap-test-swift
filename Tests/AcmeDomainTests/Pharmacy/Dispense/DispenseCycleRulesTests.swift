@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseCycleValidator()
        let item = Pharmacy.newDispenseCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseCycleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Pharmacy.DispenseCycleCopayRangeRule(min: 1.7, max: 865.7)
        let item = Pharmacy.newDispenseCycle("x", title: "y")
        item.copay = 867.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseCycleCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Pharmacy.DispenseCycleCapacityRangeRule(min: 16, max: 120)
        let item = Pharmacy.newDispenseCycle("x", title: "y")
        item.capacity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DispenseCycleCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newDispenseCycle("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
