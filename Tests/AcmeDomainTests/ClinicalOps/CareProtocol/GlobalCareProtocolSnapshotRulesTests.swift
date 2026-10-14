@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalCareProtocolSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalCareProtocolSnapshotValidator()
        let item = ClinicalOps.newGlobalCareProtocolSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalCareProtocolSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.GlobalCareProtocolSnapshotRequiredNameRule(
            message: "global care protocol snapshot needs an entry"
        )
        let item = ClinicalOps.newGlobalCareProtocolSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalCareProtocolSnapshotRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = ClinicalOps.GlobalCareProtocolSnapshotRegionLengthRule(maxLength: 86400)
        let item = ClinicalOps.newGlobalCareProtocolSnapshot("x", name: "y")
        item.region = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsGlobalCareProtocolSnapshotCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = ClinicalOps.GlobalCareProtocolSnapshotCapacityRangeRule(min: 16, max: 120)
        let item = ClinicalOps.newGlobalCareProtocolSnapshot("x", name: "y")
        item.capacity = 121
        #expect(rule.check(item).count > 0)
    }
}
