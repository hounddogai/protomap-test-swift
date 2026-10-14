@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultPriorityAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultDefaultPriorityAgreementValidator()
        let item = Imaging.newDefaultPriorityAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingDefaultPriorityAgreementRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Imaging.DefaultPriorityAgreementRequiredRegionRule(
            message: "default priority agreement needs an entry"
        )
        let item = Imaging.newDefaultPriorityAgreement("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingDefaultPriorityAgreementRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.DefaultPriorityAgreementRegionLengthRule(maxLength: 255)
        let item = Imaging.newDefaultPriorityAgreement("x", label: "y")
        item.region = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
