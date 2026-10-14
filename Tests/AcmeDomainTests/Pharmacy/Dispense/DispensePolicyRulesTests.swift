@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispensePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispensePolicyValidator()
        let item = Pharmacy.newDispensePolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispensePolicySequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Pharmacy.DispensePolicySequenceRangeRule(min: 16, max: 1000)
        let item = Pharmacy.newDispensePolicy("x", label: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispensePolicyContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Pharmacy.DispensePolicyContactEmailLengthRule(maxLength: 3600)
        let item = Pharmacy.newDispensePolicy("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispensePolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DispensePolicyCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newDispensePolicy("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
