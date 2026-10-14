@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalCareProtocolAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newGlobalCareProtocolAssignment("code-590", title: "title-258")
        let view = Imaging.toGlobalCareProtocolAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toGlobalCareProtocolAssignmentViews([item, item]).count == 2)
    }
}
