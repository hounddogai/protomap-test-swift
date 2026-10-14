@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierAllocation("code-387", title: "title-496")
        let view = Labs.toCourierAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierAllocationViews([item, item]).count == 2)
    }
}
