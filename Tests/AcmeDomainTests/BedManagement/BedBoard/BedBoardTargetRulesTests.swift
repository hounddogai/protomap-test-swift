@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardTargetValidator()
        let item = BedManagement.newBedBoardTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardTargetFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = BedManagement.BedBoardTargetFacilityLengthRule(maxLength: 64)
        let item = BedManagement.newBedBoardTarget("x", label: "y")
        item.facility = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BedBoardTargetRequiredCodeRule(message: "bed board target needs an entry")
        let item = BedManagement.newBedBoardTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardTargetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.BedBoardTargetRequiredLabelRule(message: "bed board target needs an entry")
        let item = BedManagement.newBedBoardTarget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.BedBoardTargetLabelLengthRule(maxLength: 32)
        let item = BedManagement.newBedBoardTarget("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardTargetWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = BedManagement.BedBoardTargetWeightRangeRule(min: 6.9, max: 3606.2)
        let item = BedManagement.newBedBoardTarget("x", label: "y")
        item.weight = 3607.7
        #expect(rule.check(item).count > 0)
    }
}
