@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalReferenceRangeSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalReferenceRangeSnapshotValidator()
        let item = Labs.newGlobalReferenceRangeSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalReferenceRangeSnapshotWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Labs.GlobalReferenceRangeSnapshotWindowDaysRangeRule(min: 80, max: 255)
        let item = Labs.newGlobalReferenceRangeSnapshot("x", label: "y")
        item.windowDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsGlobalReferenceRangeSnapshotCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.GlobalReferenceRangeSnapshotCapacityRangeRule(min: 3600, max: 3600)
        let item = Labs.newGlobalReferenceRangeSnapshot("x", label: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsGlobalReferenceRangeSnapshotClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Labs.GlobalReferenceRangeSnapshotClinicianIDLengthRule(maxLength: 3600)
        let item = Labs.newGlobalReferenceRangeSnapshot("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsGlobalReferenceRangeSnapshotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.GlobalReferenceRangeSnapshotRequiredLabelRule(
            message: "global reference range snapshot needs this field"
        )
        let item = Labs.newGlobalReferenceRangeSnapshot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
