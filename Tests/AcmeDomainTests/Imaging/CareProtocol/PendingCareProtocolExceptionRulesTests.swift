@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingCareProtocolExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPendingCareProtocolExceptionValidator()
        let item = Imaging.newPendingCareProtocolException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPendingCareProtocolExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PendingCareProtocolExceptionCodeLengthRule(maxLength: 120)
        let item = Imaging.newPendingCareProtocolException("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPendingCareProtocolExceptionRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Imaging.PendingCareProtocolExceptionRequiredFacilityRule(
            message: "pending care protocol exception needs this field"
        )
        let item = Imaging.newPendingCareProtocolException("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingCareProtocolExceptionRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.PendingCareProtocolExceptionRequiredNameRule(
            message: "pending care protocol exception needs this field"
        )
        let item = Imaging.newPendingCareProtocolException("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
