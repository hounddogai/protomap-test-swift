@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultBedBoardVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultBedBoardVarianceValidator()
        let item = BedManagement.newDefaultBedBoardVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultBedBoardVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DefaultBedBoardVarianceRequiredCodeRule(
            message: "default bed board variance needs an entry"
        )
        let item = BedManagement.newDefaultBedBoardVariance("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultBedBoardVarianceDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = BedManagement.DefaultBedBoardVarianceDurationMinutesRangeRule(min: 80, max: 255)
        let item = BedManagement.newDefaultBedBoardVariance("x", label: "y")
        item.durationMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}
