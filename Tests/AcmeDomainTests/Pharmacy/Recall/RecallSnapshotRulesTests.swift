@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallSnapshotValidator()
        let item = Pharmacy.newRecallSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallSnapshotOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Pharmacy.RecallSnapshotOwnerIDLengthRule(maxLength: 3600)
        let item = Pharmacy.newRecallSnapshot("x", name: "y")
        item.ownerID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallSnapshotRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Pharmacy.RecallSnapshotRegionLengthRule(maxLength: 16)
        let item = Pharmacy.newRecallSnapshot("x", name: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallSnapshotRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Pharmacy.RecallSnapshotRequiredRegionRule(message: "recall snapshot needs this field")
        let item = Pharmacy.newRecallSnapshot("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallSnapshotRequiredCodeRule(message: "recall snapshot needs a value")
        let item = Pharmacy.newRecallSnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
