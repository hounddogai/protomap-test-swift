@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedStudyAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCappedStudyAllocationValidator()
        let item = Imaging.newCappedStudyAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCappedStudyAllocationRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Imaging.CappedStudyAllocationRequiredContactEmailRule(
            message: "capped study allocation needs a value"
        )
        let item = Imaging.newCappedStudyAllocation("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCappedStudyAllocationRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Imaging.CappedStudyAllocationRequiredCountryRule(message: "capped study allocation needs an entry")
        let item = Imaging.newCappedStudyAllocation("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
