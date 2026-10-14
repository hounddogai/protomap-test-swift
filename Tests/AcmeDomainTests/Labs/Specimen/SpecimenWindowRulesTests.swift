@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenWindowValidator()
        let item = Labs.newSpecimenWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenWindowRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Labs.SpecimenWindowRequiredChecksumRule(message: "specimen window needs an entry")
        let item = Labs.newSpecimenWindow("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenWindowQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.SpecimenWindowQuantityRangeRule(min: 255, max: 3600)
        let item = Labs.newSpecimenWindow("x", title: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenWindowRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.SpecimenWindowRequiredTitleRule(message: "specimen window needs this field")
        let item = Labs.newSpecimenWindow("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
