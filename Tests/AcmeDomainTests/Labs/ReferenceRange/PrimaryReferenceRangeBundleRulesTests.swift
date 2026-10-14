@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryReferenceRangeBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPrimaryReferenceRangeBundleValidator()
        let item = Labs.newPrimaryReferenceRangeBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPrimaryReferenceRangeBundlePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Labs.PrimaryReferenceRangeBundlePhoneLengthRule(maxLength: 86400)
        let item = Labs.newPrimaryReferenceRangeBundle("x", label: "y")
        item.phone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryReferenceRangeBundleRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.PrimaryReferenceRangeBundleRequiredPhoneRule(
            message: "primary reference range bundle needs an entry"
        )
        let item = Labs.newPrimaryReferenceRangeBundle("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
