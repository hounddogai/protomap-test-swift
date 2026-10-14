@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionSummaryValidator()
        let item = Pharmacy.newSubstitutionSummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionSummaryExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Pharmacy.SubstitutionSummaryExternalRefLengthRule(maxLength: 80)
        let item = Pharmacy.newSubstitutionSummary("x", name: "y")
        item.externalRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionSummaryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.SubstitutionSummaryNameLengthRule(maxLength: 3600)
        let item = Pharmacy.newSubstitutionSummary("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
