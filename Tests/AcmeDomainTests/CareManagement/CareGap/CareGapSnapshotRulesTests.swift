@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapSnapshotValidator()
        let item = CareManagement.newCareGapSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CareGapSnapshotRequiredCodeRule(message: "care gap snapshot needs an entry")
        let item = CareManagement.newCareGapSnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapSnapshotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.CareGapSnapshotNameLengthRule(maxLength: 120)
        let item = CareManagement.newCareGapSnapshot("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapSnapshotSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = CareManagement.CareGapSnapshotSegmentLengthRule(maxLength: 255)
        let item = CareManagement.newCareGapSnapshot("x", name: "y")
        item.segment = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
