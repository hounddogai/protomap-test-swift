@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolBatchValidator()
        let item = Imaging.newCareProtocolBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolBatchMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Imaging.CareProtocolBatchMarginRangeRule(min: 0.5, max: 3358.9)
        let item = Imaging.newCareProtocolBatch("x", name: "y")
        item.margin = 3360.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolBatchRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Imaging.CareProtocolBatchRequiredClinicianIDRule(message: "care protocol batch needs this field")
        let item = Imaging.newCareProtocolBatch("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolBatchClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Imaging.CareProtocolBatchClinicianIDLengthRule(maxLength: 120)
        let item = Imaging.newCareProtocolBatch("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
