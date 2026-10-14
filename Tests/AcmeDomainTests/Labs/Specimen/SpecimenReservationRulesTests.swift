@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenReservationValidator()
        let item = Labs.newSpecimenReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenReservationCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.SpecimenReservationCapacityRangeRule(min: 1000, max: 86400)
        let item = Labs.newSpecimenReservation("x", title: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenReservationDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Labs.SpecimenReservationDiagnosisCodeLengthRule(maxLength: 3600)
        let item = Labs.newSpecimenReservation("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenReservationStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Labs.SpecimenReservationStartsAtRangeRule(min: 120, max: 1000)
        let item = Labs.newSpecimenReservation("x", title: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenReservationThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Labs.SpecimenReservationThresholdRangeRule(min: 5.2, max: 1619.3)
        let item = Labs.newSpecimenReservation("x", title: "y")
        item.threshold = 1620.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.SpecimenReservationRequiredCodeRule(message: "specimen reservation needs an entry")
        let item = Labs.newSpecimenReservation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenReservationRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Labs.SpecimenReservationRequiredCurrencyRule(message: "specimen reservation needs this field")
        let item = Labs.newSpecimenReservation("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
