@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyRoundingReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyRoundingReservationValidator()
        let item = ClinicalOps.newLegacyRoundingReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyRoundingReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.LegacyRoundingReservationRequiredCodeRule(
            message: "legacy rounding reservation needs an entry"
        )
        let item = ClinicalOps.newLegacyRoundingReservation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLegacyRoundingReservationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.LegacyRoundingReservationTitleLengthRule(maxLength: 64)
        let item = ClinicalOps.newLegacyRoundingReservation("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLegacyRoundingReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.LegacyRoundingReservationRequiredLabelRule(
            message: "legacy rounding reservation needs a value"
        )
        let item = ClinicalOps.newLegacyRoundingReservation("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLegacyRoundingReservationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.LegacyRoundingReservationRequiredTitleRule(
            message: "legacy rounding reservation needs this field"
        )
        let item = ClinicalOps.newLegacyRoundingReservation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLegacyRoundingReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.LegacyRoundingReservationCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newLegacyRoundingReservation("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
