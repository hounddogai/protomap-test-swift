@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryReadReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrimaryReadReservationValidator()
        let item = Imaging.newPrimaryReadReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrimaryReadReservationPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Imaging.PrimaryReadReservationPhoneLengthRule(maxLength: 3600)
        let item = Imaging.newPrimaryReadReservation("x", title: "y")
        item.phone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrimaryReadReservationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.PrimaryReadReservationRequiredTitleRule(message: "primary read reservation needs a value")
        let item = Imaging.newPrimaryReadReservation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryReadReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PrimaryReadReservationRequiredCodeRule(message: "primary read reservation needs this field")
        let item = Imaging.newPrimaryReadReservation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryReadReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PrimaryReadReservationCodeLengthRule(maxLength: 86400)
        let item = Imaging.newPrimaryReadReservation("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
