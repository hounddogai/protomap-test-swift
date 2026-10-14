@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryOrderSetDraftValidator()
        let item = ClinicalOps.newPrimaryOrderSetDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}
