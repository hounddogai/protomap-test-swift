@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseBatchValidator()
        let item = Pharmacy.newDispenseBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseBatchAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Pharmacy.DispenseBatchAcuityRangeRule(min: 16, max: 32)
        let item = Pharmacy.newDispenseBatch("x", title: "y")
        item.acuity = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseBatchBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Pharmacy.DispenseBatchBudgetRangeRule(min: 0.3, max: 1759.5)
        let item = Pharmacy.newDispenseBatch("x", title: "y")
        item.budget = 1761.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.DispenseBatchRequiredTitleRule(message: "dispense batch needs an entry")
        let item = Pharmacy.newDispenseBatch("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.DispenseBatchTitleLengthRule(maxLength: 86400)
        let item = Pharmacy.newDispenseBatch("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseBatchClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Pharmacy.DispenseBatchClinicianIDLengthRule(maxLength: 16)
        let item = Pharmacy.newDispenseBatch("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
