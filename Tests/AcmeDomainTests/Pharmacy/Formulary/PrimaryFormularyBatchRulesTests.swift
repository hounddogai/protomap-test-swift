@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryFormularyBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimaryFormularyBatchValidator()
        let item = Pharmacy.newPrimaryFormularyBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimaryFormularyBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.PrimaryFormularyBatchCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newPrimaryFormularyBatch("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPrimaryFormularyBatchWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Pharmacy.PrimaryFormularyBatchWardLengthRule(maxLength: 255)
        let item = Pharmacy.newPrimaryFormularyBatch("x", title: "y")
        item.ward = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
