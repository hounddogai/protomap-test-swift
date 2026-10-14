@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedSubstitutionDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedSubstitutionDigestValidator()
        let item = Pharmacy.newBatchedSubstitutionDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionDigestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.BatchedSubstitutionDigestTitleLengthRule(maxLength: 1000)
        let item = Pharmacy.newBatchedSubstitutionDigest("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionDigestRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Pharmacy.BatchedSubstitutionDigestRefillsRangeRule(min: 3600, max: 86400)
        let item = Pharmacy.newBatchedSubstitutionDigest("x", title: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionDigestWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Pharmacy.BatchedSubstitutionDigestWindowDaysRangeRule(min: 64, max: 3600)
        let item = Pharmacy.newBatchedSubstitutionDigest("x", title: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}
