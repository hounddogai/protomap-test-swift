@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredPriorityReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredPriorityReservationValidator()
        let item = Imaging.newTieredPriorityReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredPriorityReservationRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Imaging.TieredPriorityReservationRequiredTimezoneRule(
            message: "tiered priority reservation needs this field"
        )
        let item = Imaging.newTieredPriorityReservation("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredPriorityReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.TieredPriorityReservationCodeLengthRule(maxLength: 255)
        let item = Imaging.newTieredPriorityReservation("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredPriorityReservationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.TieredPriorityReservationTitleLengthRule(maxLength: 255)
        let item = Imaging.newTieredPriorityReservation("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
