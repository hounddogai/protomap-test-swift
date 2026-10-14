@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalTaskScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newGlobalTaskSchedule("code-562", label: "label-66")
        let view = ClinicalOps.toGlobalTaskScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toGlobalTaskScheduleViews([item, item]).count == 2)
    }
}
