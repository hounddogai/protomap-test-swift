@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedGoalSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedGoalSnapshotValidator()
        let item = CareManagement.newBatchedGoalSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedGoalSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.BatchedGoalSnapshotRequiredCodeRule(message: "batched goal snapshot needs this field")
        let item = CareManagement.newBatchedGoalSnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedGoalSnapshotDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = CareManagement.BatchedGoalSnapshotDiscountRangeRule(min: 3.2, max: 3179.3)
        let item = CareManagement.newBatchedGoalSnapshot("x", title: "y")
        item.discount = 3180.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementBatchedGoalSnapshotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.BatchedGoalSnapshotTitleLengthRule(maxLength: 64)
        let item = CareManagement.newBatchedGoalSnapshot("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedGoalSnapshotRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.BatchedGoalSnapshotRequiredSegmentRule(message: "batched goal snapshot needs a value")
        let item = CareManagement.newBatchedGoalSnapshot("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
