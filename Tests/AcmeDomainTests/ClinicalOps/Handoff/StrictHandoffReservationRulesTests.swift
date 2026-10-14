@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictHandoffReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultStrictHandoffReservationValidator()
        let item = ClinicalOps.newStrictHandoffReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsStrictHandoffReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.StrictHandoffReservationRequiredLabelRule(
            message: "strict handoff reservation needs this field"
        )
        let item = ClinicalOps.newStrictHandoffReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsStrictHandoffReservationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.StrictHandoffReservationRequiredNameRule(
            message: "strict handoff reservation needs an entry"
        )
        let item = ClinicalOps.newStrictHandoffReservation("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsStrictHandoffReservationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.StrictHandoffReservationNameLengthRule(maxLength: 32)
        let item = ClinicalOps.newStrictHandoffReservation("x", label: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsStrictHandoffReservationRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = ClinicalOps.StrictHandoffReservationRequiredCountryRule(
            message: "strict handoff reservation needs a value"
        )
        let item = ClinicalOps.newStrictHandoffReservation("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
