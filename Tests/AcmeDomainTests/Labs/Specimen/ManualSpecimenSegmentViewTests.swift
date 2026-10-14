@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualSpecimenSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newManualSpecimenSegment("code-657", title: "title-927")
        let view = Labs.toManualSpecimenSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toManualSpecimenSegmentViews([item, item]).count == 2)
    }
}
