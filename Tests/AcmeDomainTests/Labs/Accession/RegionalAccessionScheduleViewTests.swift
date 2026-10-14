@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalAccessionScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRegionalAccessionSchedule("code-559", title: "title-561")
        let view = Labs.toRegionalAccessionScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRegionalAccessionScheduleViews([item, item]).count == 2)
    }
}
