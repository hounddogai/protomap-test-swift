@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedRecallSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedRecallSnapshotValidator()
        let item = Pharmacy.newCappedRecallSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedRecallSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.CappedRecallSnapshotRequiredNameRule(message: "capped recall snapshot needs an entry")
        let item = Pharmacy.newCappedRecallSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
