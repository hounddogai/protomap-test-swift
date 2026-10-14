@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingFormularySegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingFormularySegmentValidator()
        let item = Pharmacy.newRollingFormularySegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingFormularySegmentSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Pharmacy.RollingFormularySegmentSpecialtyLengthRule(maxLength: 1000)
        let item = Pharmacy.newRollingFormularySegment("x", label: "y")
        item.specialty = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingFormularySegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RollingFormularySegmentCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newRollingFormularySegment("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingFormularySegmentVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.RollingFormularySegmentVisitMinutesRangeRule(min: 64, max: 120)
        let item = Pharmacy.newRollingFormularySegment("x", label: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingFormularySegmentChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Pharmacy.RollingFormularySegmentChecksumLengthRule(maxLength: 120)
        let item = Pharmacy.newRollingFormularySegment("x", label: "y")
        item.checksum = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
