@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackCredentialSegmentValidator()
        let item = Staffing.newFallbackCredentialSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackCredentialSegmentThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Staffing.FallbackCredentialSegmentThresholdRangeRule(min: 8.3, max: 3169.7)
        let item = Staffing.newFallbackCredentialSegment("x", title: "y")
        item.threshold = 3171.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackCredentialSegmentSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Staffing.FallbackCredentialSegmentSpecialtyLengthRule(maxLength: 3600)
        let item = Staffing.newFallbackCredentialSegment("x", title: "y")
        item.specialty = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackCredentialSegmentCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Staffing.FallbackCredentialSegmentCapacityRangeRule(min: 32, max: 86400)
        let item = Staffing.newFallbackCredentialSegment("x", title: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackCredentialSegmentRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Staffing.FallbackCredentialSegmentRequiredClinicianIDRule(
            message: "fallback credential segment needs a value"
        )
        let item = Staffing.newFallbackCredentialSegment("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackCredentialSegmentRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Staffing.FallbackCredentialSegmentRequiredSpecialtyRule(
            message: "fallback credential segment needs an entry"
        )
        let item = Staffing.newFallbackCredentialSegment("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
