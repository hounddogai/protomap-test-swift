@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLenientReferenceRangeSchedule("code-623", title: "title-501")
        let view = Labs.toLenientReferenceRangeScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLenientReferenceRangeScheduleViews([item, item]).count == 2)
    }
}
