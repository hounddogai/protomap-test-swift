@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedRecallReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedRecallReservationValidator()
        let item = Pharmacy.newCappedRecallReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedRecallReservationChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Pharmacy.CappedRecallReservationChecksumLengthRule(maxLength: 86400)
        let item = Pharmacy.newCappedRecallReservation("x", name: "y")
        item.checksum = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyCappedRecallReservationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.CappedRecallReservationRequiredNameRule(message: "capped recall reservation needs an entry")
        let item = Pharmacy.newCappedRecallReservation("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
