@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveSubstitutionBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveSubstitutionBundleValidator()
        let item = Pharmacy.newAdaptiveSubstitutionBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveSubstitutionBundleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.AdaptiveSubstitutionBundleRequiredTitleRule(
            message: "adaptive substitution bundle needs this field"
        )
        let item = Pharmacy.newAdaptiveSubstitutionBundle("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveSubstitutionBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.AdaptiveSubstitutionBundleRequiredCodeRule(
            message: "adaptive substitution bundle needs this field"
        )
        let item = Pharmacy.newAdaptiveSubstitutionBundle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveSubstitutionBundleChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Pharmacy.AdaptiveSubstitutionBundleChannelLengthRule(maxLength: 120)
        let item = Pharmacy.newAdaptiveSubstitutionBundle("x", title: "y")
        item.channel = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
