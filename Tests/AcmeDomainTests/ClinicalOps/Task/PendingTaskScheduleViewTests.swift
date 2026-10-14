@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingTaskScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPendingTaskSchedule("code-74", title: "title-198")
        let view = ClinicalOps.toPendingTaskScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPendingTaskScheduleViews([item, item]).count == 2)
    }
}
