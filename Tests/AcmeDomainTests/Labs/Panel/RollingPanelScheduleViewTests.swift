@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingPanelSchedule("code-175", label: "label-865")
        let view = Labs.toRollingPanelScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingPanelScheduleViews([item, item]).count == 2)
    }
}
