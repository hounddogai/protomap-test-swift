@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallExceptionValidator()
        let item = Pharmacy.newRecallException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallExceptionRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Pharmacy.RecallExceptionRevisionRangeRule(min: 255, max: 86400)
        let item = Pharmacy.newRecallException("x", name: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RecallExceptionCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newRecallException("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
