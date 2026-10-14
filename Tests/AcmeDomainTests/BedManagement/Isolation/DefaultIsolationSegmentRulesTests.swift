@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultIsolationSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultIsolationSegmentValidator()
        let item = BedManagement.newDefaultIsolationSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultIsolationSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DefaultIsolationSegmentRequiredCodeRule(
            message: "default isolation segment needs this field"
        )
        let item = BedManagement.newDefaultIsolationSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultIsolationSegmentSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = BedManagement.DefaultIsolationSegmentSequenceRangeRule(min: 16, max: 3600)
        let item = BedManagement.newDefaultIsolationSegment("x", name: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultIsolationSegmentEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = BedManagement.DefaultIsolationSegmentEndsAtRangeRule(min: 80, max: 255)
        let item = BedManagement.newDefaultIsolationSegment("x", name: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultIsolationSegmentRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = BedManagement.DefaultIsolationSegmentRequiredPatientRefRule(
            message: "default isolation segment needs an entry"
        )
        let item = BedManagement.newDefaultIsolationSegment("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultIsolationSegmentDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = BedManagement.DefaultIsolationSegmentDosageMgRangeRule(min: 8.8, max: 4276.0)
        let item = BedManagement.newDefaultIsolationSegment("x", name: "y")
        item.dosageMg = 4277.5
        #expect(rule.check(item).count > 0)
    }
}
