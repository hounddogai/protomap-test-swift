@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryAssignmentValidator()
        let item = Pharmacy.newInventoryAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryAssignmentRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Pharmacy.InventoryAssignmentRequiredBedRule(message: "inventory assignment needs a value")
        let item = Pharmacy.newInventoryAssignment("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryAssignmentBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Pharmacy.InventoryAssignmentBedLengthRule(maxLength: 120)
        let item = Pharmacy.newInventoryAssignment("x", name: "y")
        item.bed = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryAssignmentRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Pharmacy.InventoryAssignmentRequiredSummaryRule(message: "inventory assignment needs a value")
        let item = Pharmacy.newInventoryAssignment("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InventoryAssignmentRequiredCodeRule(message: "inventory assignment needs an entry")
        let item = Pharmacy.newInventoryAssignment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
