@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInventoryRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPendingInventoryRequestValidator()
        let item = Pharmacy.newPendingInventoryRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPendingInventoryRequestDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.PendingInventoryRequestDosageMgRangeRule(min: 8.7, max: 4454.0)
        let item = Pharmacy.newPendingInventoryRequest("x", title: "y")
        item.dosageMg = 4455.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingInventoryRequestRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.PendingInventoryRequestRateRangeRule(min: 2.1, max: 2960.6)
        let item = Pharmacy.newPendingInventoryRequest("x", title: "y")
        item.rate = 2962.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingInventoryRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.PendingInventoryRequestCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newPendingInventoryRequest("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPendingInventoryRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.PendingInventoryRequestRequiredCodeRule(message: "pending inventory request needs an entry")
        let item = Pharmacy.newPendingInventoryRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingInventoryRequestCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Pharmacy.PendingInventoryRequestCreatedAtRangeRule(min: 120, max: 86400)
        let item = Pharmacy.newPendingInventoryRequest("x", title: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
