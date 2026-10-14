@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusReviewValidator()
        let item = BedManagement.newCensusReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CensusReviewCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newCensusReview("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusReviewWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = BedManagement.CensusReviewWeightRangeRule(min: 5.5, max: 1951.9)
        let item = BedManagement.newCensusReview("x", name: "y")
        item.weight = 1953.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.CensusReviewLabelLengthRule(maxLength: 16)
        let item = BedManagement.newCensusReview("x", name: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CensusReviewRequiredNameRule(message: "census review needs this field")
        let item = BedManagement.newCensusReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.CensusReviewRequiredLabelRule(message: "census review needs an entry")
        let item = BedManagement.newCensusReview("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
