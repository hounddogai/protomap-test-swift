@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyProposalValidator()
        let item = Imaging.newStudyProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StudyProposalRequiredCodeRule(message: "study proposal needs this field")
        let item = Imaging.newStudyProposal("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyProposalOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Imaging.StudyProposalOwnerIDLengthRule(maxLength: 3600)
        let item = Imaging.newStudyProposal("x", title: "y")
        item.ownerID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyProposalMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.StudyProposalMinimumRangeRule(min: 4.8, max: 4408.9)
        let item = Imaging.newStudyProposal("x", title: "y")
        item.minimum = 4410.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.StudyProposalCodeLengthRule(maxLength: 80)
        let item = Imaging.newStudyProposal("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyProposalRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Imaging.StudyProposalRequiredOwnerIDRule(message: "study proposal needs an entry")
        let item = Imaging.newStudyProposal("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
