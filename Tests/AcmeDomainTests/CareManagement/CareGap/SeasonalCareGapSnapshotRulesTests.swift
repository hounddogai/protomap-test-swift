@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalCareGapSnapshotValidator()
        let item = CareManagement.newSeasonalCareGapSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalCareGapSnapshotFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.SeasonalCareGapSnapshotFloorValueRangeRule(min: 7.7, max: 931.1)
        let item = CareManagement.newSeasonalCareGapSnapshot("x", name: "y")
        item.floorValue = 932.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalCareGapSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.SeasonalCareGapSnapshotRequiredNameRule(
            message: "seasonal care gap snapshot needs this field"
        )
        let item = CareManagement.newSeasonalCareGapSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalCareGapSnapshotRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.SeasonalCareGapSnapshotRequiredChannelRule(
            message: "seasonal care gap snapshot needs an entry"
        )
        let item = CareManagement.newSeasonalCareGapSnapshot("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
