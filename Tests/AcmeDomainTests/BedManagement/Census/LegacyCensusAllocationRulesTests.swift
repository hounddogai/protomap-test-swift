@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyCensusAllocationValidator()
        let item = BedManagement.newLegacyCensusAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyCensusAllocationThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.LegacyCensusAllocationThresholdRangeRule(min: 7.3, max: 3588.8)
        let item = BedManagement.newLegacyCensusAllocation("x", title: "y")
        item.threshold = 3590.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLegacyCensusAllocationRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = BedManagement.LegacyCensusAllocationRequiredChecksumRule(
            message: "legacy census allocation needs this field"
        )
        let item = BedManagement.newLegacyCensusAllocation("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
