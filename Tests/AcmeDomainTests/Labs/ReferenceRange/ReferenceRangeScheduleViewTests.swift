@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeSchedule("code-816", name: "name-3")
        let view = Labs.toReferenceRangeScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeScheduleViews([item, item]).count == 2)
    }
}
