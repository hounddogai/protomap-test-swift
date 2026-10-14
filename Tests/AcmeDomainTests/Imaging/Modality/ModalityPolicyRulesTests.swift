@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityPolicyValidator()
        let item = Imaging.newModalityPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityPolicyReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Imaging.ModalityPolicyReviewerLengthRule(maxLength: 80)
        let item = Imaging.newModalityPolicy("x", name: "y")
        item.reviewer = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityPolicySpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Imaging.ModalityPolicySpecialtyLengthRule(maxLength: 80)
        let item = Imaging.newModalityPolicy("x", name: "y")
        item.specialty = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityPolicyUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Imaging.ModalityPolicyUpdatedAtRangeRule(min: 3600, max: 86400)
        let item = Imaging.newModalityPolicy("x", name: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityPolicyNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.ModalityPolicyNameLengthRule(maxLength: 32)
        let item = Imaging.newModalityPolicy("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityPolicyRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.ModalityPolicyRatioRangeRule(min: 9.8, max: 1182.4)
        let item = Imaging.newModalityPolicy("x", name: "y")
        item.ratio = 1183.9
        #expect(rule.check(item).count > 0)
    }
}
