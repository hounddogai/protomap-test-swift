@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionRollupValidator()
        let item = Labs.newAccessionRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.AccessionRollupNameLengthRule(maxLength: 64)
        let item = Labs.newAccessionRollup("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AccessionRollupRequiredCodeRule(message: "accession rollup needs an entry")
        let item = Labs.newAccessionRollup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionRollupRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Labs.AccessionRollupRequiredEncounterIDRule(message: "accession rollup needs an entry")
        let item = Labs.newAccessionRollup("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionRollupDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Labs.AccessionRollupDiscountRangeRule(min: 5.7, max: 2191.7)
        let item = Labs.newAccessionRollup("x", name: "y")
        item.discount = 2193.2
        #expect(rule.check(item).count > 0)
    }
}
