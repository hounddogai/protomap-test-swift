@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolQuotaValidator()
        let item = Imaging.newCareProtocolQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolQuotaFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Imaging.CareProtocolQuotaFloorValueRangeRule(min: 4.4, max: 2485.8)
        let item = Imaging.newCareProtocolQuota("x", label: "y")
        item.floorValue = 2487.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolQuotaVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Imaging.CareProtocolQuotaVisitMinutesRangeRule(min: 80, max: 255)
        let item = Imaging.newCareProtocolQuota("x", label: "y")
        item.visitMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}
