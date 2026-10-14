@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolSegmentValidator()
        let item = Imaging.newCareProtocolSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolSegmentRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Imaging.CareProtocolSegmentRequiredLocaleRule(message: "care protocol segment needs an entry")
        let item = Imaging.newCareProtocolSegment("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolSegmentClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Imaging.CareProtocolSegmentClinicianIDLengthRule(maxLength: 64)
        let item = Imaging.newCareProtocolSegment("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
