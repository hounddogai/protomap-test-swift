@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedTaskScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newWeightedTaskSchedule("code-629", title: "title-470")
        let view = ClinicalOps.toWeightedTaskScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toWeightedTaskScheduleViews([item, item]).count == 2)
    }
}
