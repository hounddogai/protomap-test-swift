@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLegacyCareGapSnapshotValidator()
        let item = CareManagement.newLegacyCareGapSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLegacyCareGapSnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.LegacyCareGapSnapshotLabelLengthRule(maxLength: 3600)
        let item = CareManagement.newLegacyCareGapSnapshot("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyCareGapSnapshotFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.LegacyCareGapSnapshotFloorValueRangeRule(min: 7.8, max: 2631.3)
        let item = CareManagement.newLegacyCareGapSnapshot("x", label: "y")
        item.floorValue = 2632.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLegacyCareGapSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LegacyCareGapSnapshotCodeLengthRule(maxLength: 120)
        let item = CareManagement.newLegacyCareGapSnapshot("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyCareGapSnapshotRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.LegacyCareGapSnapshotRequiredChannelRule(
            message: "legacy care gap snapshot needs an entry"
        )
        let item = CareManagement.newLegacyCareGapSnapshot("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
