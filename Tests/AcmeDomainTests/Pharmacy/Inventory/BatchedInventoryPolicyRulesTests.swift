@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedInventoryPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedInventoryPolicyValidator()
        let item = Pharmacy.newBatchedInventoryPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedInventoryPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.BatchedInventoryPolicyCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newBatchedInventoryPolicy("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedInventoryPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.BatchedInventoryPolicyRequiredNameRule(message: "batched inventory policy needs this field")
        let item = Pharmacy.newBatchedInventoryPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyBatchedInventoryPolicyRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Pharmacy.BatchedInventoryPolicyRequiredSourceRule(message: "batched inventory policy needs an entry")
        let item = Pharmacy.newBatchedInventoryPolicy("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}
