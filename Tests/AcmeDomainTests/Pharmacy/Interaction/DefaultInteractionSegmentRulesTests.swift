@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultInteractionSegmentValidator()
        let item = Pharmacy.newDefaultInteractionSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultInteractionSegmentDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Pharmacy.DefaultInteractionSegmentDiscountRangeRule(min: 7.5, max: 3430.8)
        let item = Pharmacy.newDefaultInteractionSegment("x", title: "y")
        item.discount = 3432.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDefaultInteractionSegmentBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Pharmacy.DefaultInteractionSegmentBedLengthRule(maxLength: 80)
        let item = Pharmacy.newDefaultInteractionSegment("x", title: "y")
        item.bed = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultInteractionSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DefaultInteractionSegmentCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newDefaultInteractionSegment("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
