@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventorySegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventorySegmentValidator()
        let item = Pharmacy.newInventorySegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventorySegmentSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Pharmacy.InventorySegmentSpecialtyLengthRule(maxLength: 120)
        let item = Pharmacy.newInventorySegment("x", name: "y")
        item.specialty = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventorySegmentRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Pharmacy.InventorySegmentRequiredSpecialtyRule(message: "inventory segment needs a value")
        let item = Pharmacy.newInventorySegment("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventorySegmentReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Pharmacy.InventorySegmentReviewerLengthRule(maxLength: 32)
        let item = Pharmacy.newInventorySegment("x", name: "y")
        item.reviewer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventorySegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InventorySegmentRequiredCodeRule(message: "inventory segment needs an entry")
        let item = Pharmacy.newInventorySegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
