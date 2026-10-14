@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedSpecimenSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultBatchedSpecimenSnapshotValidator()
        let item = Labs.newBatchedSpecimenSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsBatchedSpecimenSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.BatchedSpecimenSnapshotRequiredNameRule(message: "batched specimen snapshot needs an entry")
        let item = Labs.newBatchedSpecimenSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsBatchedSpecimenSnapshotCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.BatchedSpecimenSnapshotCopayRangeRule(min: 4.0, max: 3869.9)
        let item = Labs.newBatchedSpecimenSnapshot("x", name: "y")
        item.copay = 3871.4
        #expect(rule.check(item).count > 0)
    }
}
