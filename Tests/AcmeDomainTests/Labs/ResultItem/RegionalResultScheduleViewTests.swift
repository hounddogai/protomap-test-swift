@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalResultScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRegionalResultSchedule("code-377", name: "name-507")
        let view = Labs.toRegionalResultScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRegionalResultScheduleViews([item, item]).count == 2)
    }
}
