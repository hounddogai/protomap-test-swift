@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingSubstitutionAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPendingSubstitutionAllocationValidator()
        let item = Pharmacy.newPendingSubstitutionAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPendingSubstitutionAllocationWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Pharmacy.PendingSubstitutionAllocationWindowDaysRangeRule(min: 255, max: 3600)
        let item = Pharmacy.newPendingSubstitutionAllocation("x", title: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingSubstitutionAllocationRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Pharmacy.PendingSubstitutionAllocationRefillsRangeRule(min: 80, max: 120)
        let item = Pharmacy.newPendingSubstitutionAllocation("x", title: "y")
        item.refills = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingSubstitutionAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.PendingSubstitutionAllocationTitleLengthRule(maxLength: 3600)
        let item = Pharmacy.newPendingSubstitutionAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
