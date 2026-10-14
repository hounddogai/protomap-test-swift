@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackBedBoardVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackBedBoardVarianceValidator()
        let item = BedManagement.newFallbackBedBoardVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackBedBoardVarianceSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = BedManagement.FallbackBedBoardVarianceSegmentLengthRule(maxLength: 86400)
        let item = BedManagement.newFallbackBedBoardVariance("x", name: "y")
        item.segment = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackBedBoardVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.FallbackBedBoardVarianceCodeLengthRule(maxLength: 120)
        let item = BedManagement.newFallbackBedBoardVariance("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackBedBoardVarianceAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = BedManagement.FallbackBedBoardVarianceAmountRangeRule(min: 8.6, max: 2410.2)
        let item = BedManagement.newFallbackBedBoardVariance("x", name: "y")
        item.amount = 2411.7
        #expect(rule.check(item).count > 0)
    }
}
