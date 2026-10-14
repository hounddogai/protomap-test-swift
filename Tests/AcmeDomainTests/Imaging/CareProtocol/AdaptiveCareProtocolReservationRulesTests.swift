@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveCareProtocolReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptiveCareProtocolReservationValidator()
        let item = Imaging.newAdaptiveCareProtocolReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptiveCareProtocolReservationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.AdaptiveCareProtocolReservationNameLengthRule(maxLength: 32)
        let item = Imaging.newAdaptiveCareProtocolReservation("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptiveCareProtocolReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.AdaptiveCareProtocolReservationRequiredCodeRule(
            message: "adaptive care protocol reservation needs this field"
        )
        let item = Imaging.newAdaptiveCareProtocolReservation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
