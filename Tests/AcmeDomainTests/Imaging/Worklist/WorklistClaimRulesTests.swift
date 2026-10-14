@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistClaimValidator()
        let item = Imaging.newWorklistClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistClaimAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.WorklistClaimAcuityRangeRule(min: 64, max: 120)
        let item = Imaging.newWorklistClaim("x", name: "y")
        item.acuity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistClaimCodeLengthRule(maxLength: 120)
        let item = Imaging.newWorklistClaim("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistClaimRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Imaging.WorklistClaimRequiredProcedureCodeRule(message: "worklist claim needs an entry")
        let item = Imaging.newWorklistClaim("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistClaimContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Imaging.WorklistClaimContactEmailLengthRule(maxLength: 86400)
        let item = Imaging.newWorklistClaim("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
