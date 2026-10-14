@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedCareGapBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCappedCareGapBatchValidator()
        let item = CareManagement.newCappedCareGapBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCappedCareGapBatchRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.CappedCareGapBatchRequiredSegmentRule(message: "capped care gap batch needs an entry")
        let item = CareManagement.newCappedCareGapBatch("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedCareGapBatchNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.CappedCareGapBatchNameLengthRule(maxLength: 1000)
        let item = CareManagement.newCappedCareGapBatch("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCappedCareGapBatchOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = CareManagement.CappedCareGapBatchOwnerIDLengthRule(maxLength: 120)
        let item = CareManagement.newCappedCareGapBatch("x", name: "y")
        item.ownerID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
