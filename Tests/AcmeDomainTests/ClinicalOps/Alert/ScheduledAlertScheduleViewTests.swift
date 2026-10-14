@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledAlertScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newScheduledAlertSchedule("code-312", title: "title-375")
        let view = ClinicalOps.toScheduledAlertScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toScheduledAlertScheduleViews([item, item]).count == 2)
    }
}
