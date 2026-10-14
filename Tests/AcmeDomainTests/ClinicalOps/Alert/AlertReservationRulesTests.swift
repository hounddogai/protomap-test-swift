@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertReservationValidator()
        let item = ClinicalOps.newAlertReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertReservationRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = ClinicalOps.AlertReservationRequiredSegmentRule(message: "alert reservation needs this field")
        let item = ClinicalOps.newAlertReservation("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertReservationBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = ClinicalOps.AlertReservationBedLengthRule(maxLength: 86400)
        let item = ClinicalOps.newAlertReservation("x", title: "y")
        item.bed = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertReservationRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.AlertReservationRateRangeRule(min: 5.1, max: 4528.2)
        let item = ClinicalOps.newAlertReservation("x", title: "y")
        item.rate = 4529.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.AlertReservationCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newAlertReservation("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertReservationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.AlertReservationRequiredTitleRule(message: "alert reservation needs a value")
        let item = ClinicalOps.newAlertReservation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
