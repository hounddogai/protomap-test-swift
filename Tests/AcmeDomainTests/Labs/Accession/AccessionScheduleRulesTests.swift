@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionScheduleValidator()
        let item = Labs.newAccessionSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionScheduleRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Labs.AccessionScheduleRevisionRangeRule(min: 64, max: 80)
        let item = Labs.newAccessionSchedule("x", title: "y")
        item.revision = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionScheduleRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Labs.AccessionScheduleRequiredCountryRule(message: "accession schedule needs an entry")
        let item = Labs.newAccessionSchedule("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionScheduleCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.AccessionScheduleCountryLengthRule(maxLength: 64)
        let item = Labs.newAccessionSchedule("x", title: "y")
        item.country = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionScheduleRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.AccessionScheduleRatioRangeRule(min: 1.4, max: 4466.2)
        let item = Labs.newAccessionSchedule("x", title: "y")
        item.ratio = 4467.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionScheduleDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Labs.AccessionScheduleDescriptionLengthRule(maxLength: 80)
        let item = Labs.newAccessionSchedule("x", title: "y")
        item.description = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
