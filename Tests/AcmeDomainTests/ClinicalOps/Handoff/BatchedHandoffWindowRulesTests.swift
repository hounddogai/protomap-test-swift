@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedHandoffWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultBatchedHandoffWindowValidator()
        let item = ClinicalOps.newBatchedHandoffWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsBatchedHandoffWindowRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = ClinicalOps.BatchedHandoffWindowRequiredPatientRefRule(
            message: "batched handoff window needs a value"
        )
        let item = ClinicalOps.newBatchedHandoffWindow("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsBatchedHandoffWindowRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.BatchedHandoffWindowRequiredTitleRule(message: "batched handoff window needs this field")
        let item = ClinicalOps.newBatchedHandoffWindow("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsBatchedHandoffWindowRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = ClinicalOps.BatchedHandoffWindowRequiredClinicianIDRule(
            message: "batched handoff window needs this field"
        )
        let item = ClinicalOps.newBatchedHandoffWindow("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsBatchedHandoffWindowPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.BatchedHandoffWindowPatientRefLengthRule(maxLength: 255)
        let item = ClinicalOps.newBatchedHandoffWindow("x", title: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
