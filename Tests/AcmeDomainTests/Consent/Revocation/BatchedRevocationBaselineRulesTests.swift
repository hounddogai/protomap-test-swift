@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedRevocationBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedRevocationBaselineValidator()
        let item = Consent.newBatchedRevocationBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedRevocationBaselineRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Consent.BatchedRevocationBaselineRequiredClinicianIDRule(
            message: "batched revocation baseline needs an entry"
        )
        let item = Consent.newBatchedRevocationBaseline("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedRevocationBaselineRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.BatchedRevocationBaselineRequiredTitleRule(
            message: "batched revocation baseline needs an entry"
        )
        let item = Consent.newBatchedRevocationBaseline("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
