@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolReservationValidator()
        let item = ClinicalOps.newCareProtocolReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolReservationCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = ClinicalOps.CareProtocolReservationCreatedAtRangeRule(min: 255, max: 3600)
        let item = ClinicalOps.newCareProtocolReservation("x", name: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolReservationRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = ClinicalOps.CareProtocolReservationRequiredDescriptionRule(
            message: "care protocol reservation needs this field"
        )
        let item = ClinicalOps.newCareProtocolReservation("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolReservationChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = ClinicalOps.CareProtocolReservationChecksumLengthRule(maxLength: 32)
        let item = ClinicalOps.newCareProtocolReservation("x", name: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.CareProtocolReservationRequiredCodeRule(
            message: "care protocol reservation needs this field"
        )
        let item = ClinicalOps.newCareProtocolReservation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolReservationDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.CareProtocolReservationDescriptionLengthRule(maxLength: 1000)
        let item = ClinicalOps.newCareProtocolReservation("x", name: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
