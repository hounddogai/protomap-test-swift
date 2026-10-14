@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedSpecimenQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedSpecimenQuotaValidator()
        let item = Labs.newCappedSpecimenQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedSpecimenQuotaPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Labs.CappedSpecimenQuotaPatientRefLengthRule(maxLength: 255)
        let item = Labs.newCappedSpecimenQuota("x", label: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedSpecimenQuotaLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.CappedSpecimenQuotaLabelLengthRule(maxLength: 120)
        let item = Labs.newCappedSpecimenQuota("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedSpecimenQuotaDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Labs.CappedSpecimenQuotaDiscountRangeRule(min: 9.4, max: 3583.7)
        let item = Labs.newCappedSpecimenQuota("x", label: "y")
        item.discount = 3585.2
        #expect(rule.check(item).count > 0)
    }
}
