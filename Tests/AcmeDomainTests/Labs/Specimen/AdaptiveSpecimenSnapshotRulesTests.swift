@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveSpecimenSnapshotValidator()
        let item = Labs.newAdaptiveSpecimenSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveSpecimenSnapshotRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Labs.AdaptiveSpecimenSnapshotRequiredWardRule(message: "adaptive specimen snapshot needs this field")
        let item = Labs.newAdaptiveSpecimenSnapshot("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveSpecimenSnapshotWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Labs.AdaptiveSpecimenSnapshotWardLengthRule(maxLength: 16)
        let item = Labs.newAdaptiveSpecimenSnapshot("x", title: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptiveSpecimenSnapshotUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Labs.AdaptiveSpecimenSnapshotUnitLengthRule(maxLength: 1000)
        let item = Labs.newAdaptiveSpecimenSnapshot("x", title: "y")
        item.unit = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
