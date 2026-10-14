@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeRequest("code-983", label: "label-807")
        let view = Labs.toReferenceRangeRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeRequestViews([item, item]).count == 2)
    }
}
