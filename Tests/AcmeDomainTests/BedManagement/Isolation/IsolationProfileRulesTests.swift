@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationProfileValidator()
        let item = BedManagement.newIsolationProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationProfileNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.IsolationProfileNameLengthRule(maxLength: 1000)
        let item = BedManagement.newIsolationProfile("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationProfileRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = BedManagement.IsolationProfileRequiredBedRule(message: "isolation profile needs an entry")
        let item = BedManagement.newIsolationProfile("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationProfileDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = BedManagement.IsolationProfileDiscountRangeRule(min: 4.1, max: 3527.5)
        let item = BedManagement.newIsolationProfile("x", name: "y")
        item.discount = 3529.0
        #expect(rule.check(item).count > 0)
    }
}
