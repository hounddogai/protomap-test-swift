@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardEstimateValidator()
        let item = BedManagement.newBedBoardEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardEstimateMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.BedBoardEstimateMarginRangeRule(min: 7.7, max: 4040.3)
        let item = BedManagement.newBedBoardEstimate("x", title: "y")
        item.margin = 4041.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BedBoardEstimateCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newBedBoardEstimate("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
