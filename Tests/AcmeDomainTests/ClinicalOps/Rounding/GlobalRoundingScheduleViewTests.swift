@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalRoundingScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newGlobalRoundingSchedule("code-658", label: "label-734")
        let view = ClinicalOps.toGlobalRoundingScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toGlobalRoundingScheduleViews([item, item]).count == 2)
    }
}
