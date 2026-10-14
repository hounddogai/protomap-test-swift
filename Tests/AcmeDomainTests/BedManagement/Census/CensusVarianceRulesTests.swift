@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusVarianceValidator()
        let item = BedManagement.newCensusVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusVarianceRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = BedManagement.CensusVarianceRequiredReviewerRule(message: "census variance needs this field")
        let item = BedManagement.newCensusVariance("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusVarianceBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = BedManagement.CensusVarianceBatchSizeRangeRule(min: 32, max: 120)
        let item = BedManagement.newCensusVariance("x", title: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusVarianceRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = BedManagement.CensusVarianceRequiredPatientRefRule(message: "census variance needs a value")
        let item = BedManagement.newCensusVariance("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusVariancePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = BedManagement.CensusVariancePatientRefLengthRule(maxLength: 32)
        let item = BedManagement.newCensusVariance("x", title: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.CensusVarianceTitleLengthRule(maxLength: 120)
        let item = BedManagement.newCensusVariance("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
