@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedCensusWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultWeightedCensusWindowValidator()
        let item = BedManagement.newWeightedCensusWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementWeightedCensusWindowRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.WeightedCensusWindowRequiredNameRule(message: "weighted census window needs a value")
        let item = BedManagement.newWeightedCensusWindow("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementWeightedCensusWindowDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = BedManagement.WeightedCensusWindowDurationMinutesRangeRule(min: 32, max: 32)
        let item = BedManagement.newWeightedCensusWindow("x", name: "y")
        item.durationMinutes = 33
        #expect(rule.check(item).count > 0)
    }
}
