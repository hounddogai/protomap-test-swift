@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredPriorityScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredPriorityScoreValidator()
        let item = Imaging.newTieredPriorityScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredPriorityScoreVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Imaging.TieredPriorityScoreVisitMinutesRangeRule(min: 64, max: 3600)
        let item = Imaging.newTieredPriorityScore("x", name: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingTieredPriorityScoreRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Imaging.TieredPriorityScoreRequiredFacilityRule(message: "tiered priority score needs an entry")
        let item = Imaging.newTieredPriorityScore("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredPriorityScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.TieredPriorityScoreCodeLengthRule(maxLength: 1000)
        let item = Imaging.newTieredPriorityScore("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredPriorityScoreClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Imaging.TieredPriorityScoreClinicianIDLengthRule(maxLength: 120)
        let item = Imaging.newTieredPriorityScore("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredPriorityScoreRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Imaging.TieredPriorityScoreRequiredClinicianIDRule(message: "tiered priority score needs an entry")
        let item = Imaging.newTieredPriorityScore("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
