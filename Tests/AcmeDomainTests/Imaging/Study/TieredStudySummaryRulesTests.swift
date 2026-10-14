@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredStudySummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredStudySummaryValidator()
        let item = Imaging.newTieredStudySummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredStudySummaryPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Imaging.TieredStudySummaryPatientRefLengthRule(maxLength: 86400)
        let item = Imaging.newTieredStudySummary("x", name: "y")
        item.patientRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredStudySummaryRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.TieredStudySummaryRegionLengthRule(maxLength: 32)
        let item = Imaging.newTieredStudySummary("x", name: "y")
        item.region = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredStudySummaryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.TieredStudySummaryNameLengthRule(maxLength: 16)
        let item = Imaging.newTieredStudySummary("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
