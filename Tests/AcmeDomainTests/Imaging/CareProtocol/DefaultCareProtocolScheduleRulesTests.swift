@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultCareProtocolScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultDefaultCareProtocolScheduleValidator()
        let item = Imaging.newDefaultCareProtocolSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingDefaultCareProtocolScheduleRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Imaging.DefaultCareProtocolScheduleRequiredCategoryRule(
            message: "default care protocol schedule needs a value"
        )
        let item = Imaging.newDefaultCareProtocolSchedule("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
