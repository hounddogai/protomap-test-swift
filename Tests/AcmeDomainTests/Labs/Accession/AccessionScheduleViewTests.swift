@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionSchedule("code-495", title: "title-883")
        let view = Labs.toAccessionScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionScheduleViews([item, item]).count == 2)
    }
}
