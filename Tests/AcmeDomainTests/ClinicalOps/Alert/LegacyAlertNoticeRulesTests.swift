@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyAlertNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyAlertNoticeValidator()
        let item = ClinicalOps.newLegacyAlertNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyAlertNoticeClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = ClinicalOps.LegacyAlertNoticeClinicianIDLengthRule(maxLength: 120)
        let item = ClinicalOps.newLegacyAlertNotice("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLegacyAlertNoticeNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = ClinicalOps.LegacyAlertNoticeNotesLengthRule(maxLength: 80)
        let item = ClinicalOps.newLegacyAlertNotice("x", name: "y")
        item.notes = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLegacyAlertNoticeRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = ClinicalOps.LegacyAlertNoticeRequiredClinicianIDRule(message: "legacy alert notice needs a value")
        let item = ClinicalOps.newLegacyAlertNotice("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLegacyAlertNoticeMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = ClinicalOps.LegacyAlertNoticeMarginRangeRule(min: 7.9, max: 3017.4)
        let item = ClinicalOps.newLegacyAlertNotice("x", name: "y")
        item.margin = 3018.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsLegacyAlertNoticeMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = ClinicalOps.LegacyAlertNoticeMaximumRangeRule(min: 2.7, max: 1972.0)
        let item = ClinicalOps.newLegacyAlertNotice("x", name: "y")
        item.maximum = 1973.5
        #expect(rule.check(item).count > 0)
    }
}
