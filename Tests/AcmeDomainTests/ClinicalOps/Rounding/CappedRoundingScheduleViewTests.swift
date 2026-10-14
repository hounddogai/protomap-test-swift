@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedRoundingScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newCappedRoundingSchedule("code-572", label: "label-419")
        let view = ClinicalOps.toCappedRoundingScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toCappedRoundingScheduleViews([item, item]).count == 2)
    }
}
