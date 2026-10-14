@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityRequest("code-667", name: "name-65")
        let view = Imaging.toPriorityRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityRequestViews([item, item]).count == 2)
    }
}
