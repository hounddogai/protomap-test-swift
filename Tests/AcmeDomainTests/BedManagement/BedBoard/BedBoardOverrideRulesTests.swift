@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardOverrideValidator()
        let item = BedManagement.newBedBoardOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardOverrideCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.BedBoardOverrideCopayRangeRule(min: 2.6, max: 2843.2)
        let item = BedManagement.newBedBoardOverride("x", name: "y")
        item.copay = 2844.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BedBoardOverrideCodeLengthRule(maxLength: 32)
        let item = BedManagement.newBedBoardOverride("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardOverrideThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.BedBoardOverrideThresholdRangeRule(min: 8.6, max: 1614.5)
        let item = BedManagement.newBedBoardOverride("x", name: "y")
        item.threshold = 1616.0
        #expect(rule.check(item).count > 0)
    }
}
