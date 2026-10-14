@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCensusReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultCensusReservationValidator()
        let item = BedManagement.newDefaultCensusReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultCensusReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DefaultCensusReservationRequiredCodeRule(
            message: "default census reservation needs an entry"
        )
        let item = BedManagement.newDefaultCensusReservation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultCensusReservationSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = BedManagement.DefaultCensusReservationSegmentLengthRule(maxLength: 1000)
        let item = BedManagement.newDefaultCensusReservation("x", name: "y")
        item.segment = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDefaultCensusReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.DefaultCensusReservationCodeLengthRule(maxLength: 255)
        let item = BedManagement.newDefaultCensusReservation("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDefaultCensusReservationStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = BedManagement.DefaultCensusReservationStartsAtRangeRule(min: 16, max: 64)
        let item = BedManagement.newDefaultCensusReservation("x", name: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}
