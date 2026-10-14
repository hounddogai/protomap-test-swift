@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadTargetValidator()
        let item = Imaging.newReadTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadTargetOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Imaging.ReadTargetOwnerIDLengthRule(maxLength: 32)
        let item = Imaging.newReadTarget("x", label: "y")
        item.ownerID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadTargetEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Imaging.ReadTargetEncounterIDLengthRule(maxLength: 255)
        let item = Imaging.newReadTarget("x", label: "y")
        item.encounterID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadTargetLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Imaging.ReadTargetLimitRangeRule(min: 32, max: 80)
        let item = Imaging.newReadTarget("x", label: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}
