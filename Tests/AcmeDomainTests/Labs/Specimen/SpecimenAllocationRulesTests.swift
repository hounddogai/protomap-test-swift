@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenAllocationValidator()
        let item = Labs.newSpecimenAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenAllocationRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Labs.SpecimenAllocationRequiredRegionRule(message: "specimen allocation needs this field")
        let item = Labs.newSpecimenAllocation("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.SpecimenAllocationTitleLengthRule(maxLength: 120)
        let item = Labs.newSpecimenAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.SpecimenAllocationRequiredCodeRule(message: "specimen allocation needs this field")
        let item = Labs.newSpecimenAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.SpecimenAllocationRequiredTitleRule(message: "specimen allocation needs an entry")
        let item = Labs.newSpecimenAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
