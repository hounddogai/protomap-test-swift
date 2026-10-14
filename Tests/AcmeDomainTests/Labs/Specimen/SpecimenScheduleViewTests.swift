@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenSchedule("code-388", title: "title-320")
        let view = Labs.toSpecimenScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenScheduleViews([item, item]).count == 2)
    }
}
