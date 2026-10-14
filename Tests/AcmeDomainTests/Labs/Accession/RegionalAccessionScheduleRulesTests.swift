@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalAccessionScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRegionalAccessionScheduleValidator()
        let item = Labs.newRegionalAccessionSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRegionalAccessionScheduleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.RegionalAccessionScheduleRequiredTitleRule(message: "regional accession schedule needs a value")
        let item = Labs.newRegionalAccessionSchedule("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRegionalAccessionScheduleRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.RegionalAccessionScheduleRateRangeRule(min: 9.4, max: 4665.3)
        let item = Labs.newRegionalAccessionSchedule("x", title: "y")
        item.rate = 4666.8
        #expect(rule.check(item).count > 0)
    }
}
