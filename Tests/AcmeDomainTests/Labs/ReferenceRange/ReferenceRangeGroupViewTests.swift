@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeGroup("code-635", label: "label-236")
        let view = Labs.toReferenceRangeGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeGroupViews([item, item]).count == 2)
    }
}
