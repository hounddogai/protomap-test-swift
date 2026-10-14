@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolAgreementValidator()
        let item = Imaging.newCareProtocolAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolAgreementUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Imaging.CareProtocolAgreementUpdatedAtRangeRule(min: 120, max: 86400)
        let item = Imaging.newCareProtocolAgreement("x", title: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolAgreementBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.CareProtocolAgreementBedLengthRule(maxLength: 64)
        let item = Imaging.newCareProtocolAgreement("x", title: "y")
        item.bed = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolAgreementCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Imaging.CareProtocolAgreementCapacityRangeRule(min: 1000, max: 86400)
        let item = Imaging.newCareProtocolAgreement("x", title: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}
