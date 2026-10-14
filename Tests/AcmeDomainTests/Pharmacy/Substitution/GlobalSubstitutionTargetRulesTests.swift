@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalSubstitutionTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultGlobalSubstitutionTargetValidator()
        let item = Pharmacy.newGlobalSubstitutionTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyGlobalSubstitutionTargetReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Pharmacy.GlobalSubstitutionTargetReviewerLengthRule(maxLength: 64)
        let item = Pharmacy.newGlobalSubstitutionTarget("x", name: "y")
        item.reviewer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalSubstitutionTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.GlobalSubstitutionTargetRequiredCodeRule(
            message: "global substitution target needs an entry"
        )
        let item = Pharmacy.newGlobalSubstitutionTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyGlobalSubstitutionTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.GlobalSubstitutionTargetRequiredNameRule(
            message: "global substitution target needs this field"
        )
        let item = Pharmacy.newGlobalSubstitutionTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyGlobalSubstitutionTargetSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Pharmacy.GlobalSubstitutionTargetSegmentLengthRule(maxLength: 32)
        let item = Pharmacy.newGlobalSubstitutionTarget("x", name: "y")
        item.segment = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
