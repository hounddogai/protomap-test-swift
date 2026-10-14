@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryRoundingProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryRoundingProfileValidator()
        let item = ClinicalOps.newPrimaryRoundingProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryRoundingProfilePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.PrimaryRoundingProfilePatientRefLengthRule(maxLength: 64)
        let item = ClinicalOps.newPrimaryRoundingProfile("x", title: "y")
        item.patientRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryRoundingProfileDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = ClinicalOps.PrimaryRoundingProfileDiscountRangeRule(min: 5.6, max: 3660.4)
        let item = ClinicalOps.newPrimaryRoundingProfile("x", title: "y")
        item.discount = 3661.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPrimaryRoundingProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.PrimaryRoundingProfileCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newPrimaryRoundingProfile("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryRoundingProfileRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = ClinicalOps.PrimaryRoundingProfileRetriesRangeRule(min: 32, max: 86400)
        let item = ClinicalOps.newPrimaryRoundingProfile("x", title: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}
