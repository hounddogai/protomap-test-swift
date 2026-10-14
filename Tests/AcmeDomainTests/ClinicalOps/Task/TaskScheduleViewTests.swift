@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskSchedule("code-651", name: "name-262")
        let view = ClinicalOps.toTaskScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskScheduleViews([item, item]).count == 2)
    }
}
