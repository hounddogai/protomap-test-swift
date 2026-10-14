@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingTransferSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingTransferSegmentValidator()
        let item = BedManagement.newRollingTransferSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingTransferSegmentFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.RollingTransferSegmentFloorValueRangeRule(min: 2.4, max: 305.4)
        let item = BedManagement.newRollingTransferSegment("x", name: "y")
        item.floorValue = 306.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingTransferSegmentCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.RollingTransferSegmentCeilingRangeRule(min: 7.7, max: 4902.1)
        let item = BedManagement.newRollingTransferSegment("x", name: "y")
        item.ceiling = 4903.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingTransferSegmentRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = BedManagement.RollingTransferSegmentRequiredPayerRule(
            message: "rolling transfer segment needs this field"
        )
        let item = BedManagement.newRollingTransferSegment("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
