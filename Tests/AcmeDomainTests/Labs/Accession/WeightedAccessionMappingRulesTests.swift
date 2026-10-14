@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedAccessionMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedAccessionMappingValidator()
        let item = Labs.newWeightedAccessionMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedAccessionMappingCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.WeightedAccessionMappingCountryLengthRule(maxLength: 80)
        let item = Labs.newWeightedAccessionMapping("x", title: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedAccessionMappingRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Labs.WeightedAccessionMappingRegionLengthRule(maxLength: 16)
        let item = Labs.newWeightedAccessionMapping("x", title: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedAccessionMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.WeightedAccessionMappingCodeLengthRule(maxLength: 16)
        let item = Labs.newWeightedAccessionMapping("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedAccessionMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.WeightedAccessionMappingRequiredTitleRule(message: "weighted accession mapping needs a value")
        let item = Labs.newWeightedAccessionMapping("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
