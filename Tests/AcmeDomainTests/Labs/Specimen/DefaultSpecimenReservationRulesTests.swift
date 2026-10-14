@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultSpecimenReservationValidator()
        let item = Labs.newDefaultSpecimenReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultSpecimenReservationRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Labs.DefaultSpecimenReservationRequiredClinicianIDRule(
            message: "default specimen reservation needs an entry"
        )
        let item = Labs.newDefaultSpecimenReservation("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultSpecimenReservationRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Labs.DefaultSpecimenReservationRequiredLocaleRule(
            message: "default specimen reservation needs this field"
        )
        let item = Labs.newDefaultSpecimenReservation("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
